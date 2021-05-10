# Setup

## Tools

Installation script: [cli-tools.sh](https://github.com/lakermann/iot-accelerator-game/blob/main/deployment/cli-tools.sh)

| Tool          | Version  | Description                                          |
| ------------- | -------- | ---------------------------------------------------- |
| `azure-cli`   | 2.22.1   | Setup Azure backend infrastructure [^1]              |
| `mssql-tools` | 17.7.1.1 | Create database table [^2]                           |
| `heroku`      | 7.52.0   | Setup and deploy frontend to heroku (optional)  [^3] |

## Backend Services

### Azure Resources

* Resource Group
  * Event Hubs Namespace [^4]
    * Event Hub 
      * Authorization Rule "Sensor" (Send)
      * Authorization Rule "Stream Analytics" (Listen)
  * SQL Server [^5]
    * SQL Database
      * Firewall Rule "Azure Services"
      * Firewall Rule "Cli"
  * Stream Analytics Job [^6]
    * Input "Event Hub"
    * Output "SQL Database"
    * Transformation [^7]

### Azure Deployment

Deployment script: [backend-azure.sh](https://github.com/lakermann/iot-accelerator-game/blob/main/deployment/backend-azure.sh)

```bash
Usage: ./backend-azure.sh <command>
where <command> is one of the following
  create
  cleanup
```

* `create`: create all needed resources in a new resource group in an already existing subscription
* `cleanup`: delete the resource group with all resources

#### Configuration Azure Script

| Property                      | Description                                                  |
| ----------------------------- | ------------------------------------------------------------ |
| `subscription`                | Name or ID of subscription.                                  |
| `event_hubs_namespace`        | Event hub namespace, provides network endpoints.             |
| `mssql_server_admin_user`     | Administrator username for the server.                       |
| `mssql_server_admin_password` | Administrator login password.                                |
| `mssql_server_ip_whitelist`   | IPv4 address of the firewall rule, used for database access. |

#### Output

```bash
MSSQL connection details
  Host: ...
  Database: ...
Event Hub connection details
  URI: ...
  SAS Token: ... (validity: 24 hours)
```

## Frontend 

Vue.js[^8] web app to collect and push accelerometer events.

### Local Development

#### Configuration `.env`

| Property                            | Description                                  |
| ----------------------------------- | -------------------------------------------- |
| `VUE_APP_POST_INTERVAL`             | Http post interval (ms)                      |
| `VUE_APP_POST_URL`                  | Http post url (event hub URI)                |
| `VUE_APP_POST_AUTHORIZATION_HEADER` | Http post access token (event hub SAS Token) |

### Heroku Deployment

Deployment script: [frontend-heroku.sh](https://github.com/lakermann/iot-accelerator-game/blob/main/deployment/frontend-heroku.sh)

```bash
Usage: ./frontend-heroku.sh <command>
where <command> is one of the following
  init
  create
```

* `create`: create heroku app
* `cleanup`: destroy heroku app

#### Configuration Heroku Script

| Property                    | Description                                  |
| --------------------------- | -------------------------------------------- |
| `application_name`          | Heroku application name                      |
| `post_interval`             | Http post interval (ms)                      |
| `post_url`                  | Http post url (event hub URI)                |
| `post_authorization_header` | Http post access token (event hub SAS Token) |

In this demo project, the secrets are stored in the app. Usually do not store any secrets (such as private API keys) in
your app! Environment variables are embedded into the build, meaning anyone can view them by inspecting your app's
files.

## Ranking

```sql
SELECT username, AVG(acceleration_magnitude) AS average_acceleration_magnitude
FROM METRICS
GROUP BY username
ORDER BY average_acceleration_magnitude DESC;
```

[^1]: <https://docs.microsoft.com/en-us/cli/azure/>
[^2]: <https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility>
[^3]: <https://devcenter.heroku.com/articles/heroku-cli>
[^4]: <https://docs.microsoft.com/en-us/azure/event-hubs/>
[^5]: <https://docs.microsoft.com/en-us/azure/azure-sql/>
[^6]: <https://docs.microsoft.com/en-us/azure/stream-analytics/>
[^7]: <https://docs.microsoft.com/en-us/stream-analytics-query/stream-analytics-query-language-reference>
[^8]: <https://vuejs.org>

