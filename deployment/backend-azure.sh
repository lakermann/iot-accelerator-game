#!/bin/bash

readonly subscription=                                          # set subscription id
readonly event_hubs_namespace=                                  # set eventhub namespace
readonly mssql_server_admin_user=                               # set sql admin user
readonly mssql_server_admin_password=                           # set sql admin password
readonly mssql_server_ip_whitelist=                             # set ip address for external database access
readonly location=SwitzerlandNorth                              # set location
readonly stream_analytics_location=westeurope                   # set location for stream analytics

readonly resource_group_name=iot-accelerator-game
readonly event_hub_name=iot-accelerator-game-eventhub
readonly event_hub_rule_name_sensor=sensor
readonly event_hub_rule_name_stream_analytics=stream-analytics
readonly mssql_server_name=iot-accelerator-game-db-srv
readonly mssql_database_name=iot-accelerator-game-db
readonly stream_analytics_job_name=iot-accelerator-game-stream-analytics-job
readonly stream_analytics_job_input_name=eventhub
readonly stream_analytics_job_output_name=mssql

login() {
  echo "Login"
  az login
}

logout() {
  echo "Logout"
  az logout
}

create_resource_group() {
  echo "Create Resource Group"
  # Set the subscription context
  az account set --subscription $subscription
  # Create a resource group.
  az group create --name $resource_group_name --location $location
}

create_eventhub() {
  echo "Create Event Hub"
  # Create an event hubs namespace.
  az eventhubs namespace create --name $event_hubs_namespace --resource-group $resource_group_name --location $location --sku Basic --capacity 1 --zone-redundant false
  # Create an event hub.
  az eventhubs eventhub create --name $event_hub_name --resource-group $resource_group_name --namespace-name $event_hubs_namespace --enable-capture false --message-retention 1 --partition-count 1
  # Create an authorization rule for sensors.
  az eventhubs eventhub authorization-rule create --resource-group $resource_group_name --namespace-name $event_hubs_namespace --eventhub-name $event_hub_name --name $event_hub_rule_name_sensor --rights Send
  # Create an authorization rule for stream analytics.
  az eventhubs eventhub authorization-rule create --resource-group $resource_group_name --namespace-name $event_hubs_namespace --eventhub-name $event_hub_name --name $event_hub_rule_name_stream_analytics --rights Listen
}

create_mssql_database() {
  echo "Create MSSQL Database"
  # Create sql server.
  az sql server create --resource-group $resource_group_name --location $location --name $mssql_server_name --admin-user $mssql_server_admin_user --admin-password $mssql_server_admin_password --enable-public-network true
  # Create a serverless database.
  az sql db create --resource-group $resource_group_name --server $mssql_server_name --name $mssql_database_name --edition GeneralPurpose --family Gen5 --capacity 1 --compute-model Serverless --auto-pause-delay 60 --zone-redundant false --max-size 1GB
  # Create a firewall rule for azure services.
  az sql server firewall-rule create --resource-group $resource_group_name --server $mssql_server_name --name azure-services --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0
  # Create a firewall rule for cli.
  az sql server firewall-rule create --resource-group $resource_group_name --server $mssql_server_name --name cli --start-ip-address $mssql_server_ip_whitelist --end-ip-address $mssql_server_ip_whitelist
  # Create database schema.
  sqlcmd -S $mssql_server_name.database.windows.net -d $mssql_database_name -U $mssql_server_admin_user -P $mssql_server_admin_password -i ./db-schema.sql
}

create_stream_analytics() {
  echo "Create Stream Analytics"
  local shared_access_policy_key
  shared_access_policy_key=$(get_eventhub_shared_access_policy_key $event_hub_rule_name_stream_analytics)
  # Create an stream analytics job.
  az stream-analytics job create --resource-group $resource_group_name --name $stream_analytics_job_name --location $stream_analytics_location --output-error-policy Drop
  # Add event hub input to stream analytics job.
  az stream-analytics input create --resource-group $resource_group_name --job-name $stream_analytics_job_name --name $stream_analytics_job_input_name --type Stream \
    --datasource "{'type': 'Microsoft.ServiceBus/EventHub', 'properties': {'serviceBusNamespace': '$event_hubs_namespace' ,'sharedAccessPolicyName': '${event_hub_rule_name_stream_analytics}', 'sharedAccessPolicyKey': '${shared_access_policy_key}', 'eventHubName': '${event_hub_name}'}}" \
    --serialization "{'type': 'Json', 'properties': {'encoding': 'UTF8'}}"
  # Add mssql database output to stream analytics job.
  az stream-analytics output create --resource-group $resource_group_name --job-name $stream_analytics_job_name --name $stream_analytics_job_output_name \
    --datasource "{'type': 'Microsoft.Sql/Server/Database','properties': {'server': '$mssql_server_name','database': '$mssql_database_name','user': '$mssql_server_admin_user','password': '$mssql_server_admin_password','table': 'METRICS'}}"
  # Create a transformation
  az stream-analytics transformation create --resource-group $resource_group_name --job-name $stream_analytics_job_name --name Transformation --streaming-units "1" --transformation-query @transformation-query.sql
  # Start the streaming job
  az stream-analytics job start --resource-group $resource_group_name --name $stream_analytics_job_name --output-start-mode JobStartTime
}

get_eventhub_shared_access_policy_key() {
  local event_hub_rule_name=$1
  keys=$(az eventhubs eventhub authorization-rule keys list --resource-group $resource_group_name --namespace-name $event_hubs_namespace --eventhub-name $event_hub_name --name "$event_hub_rule_name")
  echo "${keys}" | jq -r '.primaryKey'
}

# https://docs.microsoft.com/en-us/rest/api/eventhub/generate-sas-token
get_sas_token() {
  local eventhub_uri=$1
  local shared_access_key_name=$2
  local shared_access_key=$3
  local expiry=${expiry:=$((60 * 60 * 24))} # Default token expiry is 1 day

  local encoded_uri utf8_signature hash encoded_hash
  encoded_uri=$(echo -n "$eventhub_uri" | jq -s -R -r @uri)
  local ttl=$(($(date +%s) + expiry))
  utf8_signature=$(printf "%s\n%s" "$encoded_uri" $ttl | iconv -t utf8)
  hash=$(echo -n "$utf8_signature" | openssl sha256 -hmac "$shared_access_key" -binary | base64)
  encoded_hash=$(echo -n "$hash" | jq -s -R -r @uri)

  echo -n "SharedAccessSignature sr=$encoded_uri&sig=$encoded_hash&se=$ttl&skn=$shared_access_key_name"
}

get_mssql_connection_details() {
  echo "MSSQL connection details"
  echo "  Host: $mssql_server_name.database.windows.net"
  echo "  Database: $mssql_database_name"
}

get_eventhub_connection_details() {
  local shared_access_policy_key
  shared_access_policy_key=$(get_eventhub_shared_access_policy_key $event_hub_rule_name_sensor)
  echo "Event Hub connection details"
  echo "  URI: https://$event_hubs_namespace.servicebus.windows.net/$event_hub_name/messages"
  sasToken=$(get_sas_token https://$event_hubs_namespace.servicebus.windows.net/ $event_hub_rule_name_sensor "$shared_access_policy_key")
  echo "  SAS Token: $sasToken"
}

deleteResourceGroup() {
  echo "Delete resource group"
  az group delete --name $resource_group_name
}

create() {
  login
  create_resource_group
  create_eventhub
  create_mssql_database
  create_stream_analytics
  get_mssql_connection_details
  get_eventhub_connection_details
  logout
}

cleanup() {
  login
  deleteResourceGroup
  logout
}

usage() {
  echo "Usage: $0 <command>"
  echo "where <command> is one of the following"
  echo "  create"
  echo "  cleanup"
  echo
}

main() {
  local command=$1
  case ${command} in
  create)
    create
    ;;
  cleanup)
    cleanup
    ;;
  *)
    echo "Unknown command ${command}"
    usage
    exit 1
    ;;
  esac
}

main "$@"
