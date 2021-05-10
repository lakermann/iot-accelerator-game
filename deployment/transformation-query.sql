SELECT eventhub.acceleration.x                 AS acceleration_x,
       eventhub.acceleration.y                 AS acceleration_y,
       eventhub.acceleration.z                 AS acceleration_z,
       eventhub.username                       AS username,
       SQRT(POWER(eventhub.acceleration.x, 2) * POWER(eventhub.acceleration.y, 2) *
            POWER(eventhub.acceleration.z, 2)) as acceleration_magnitude
INTO
    [mssql]
FROM
    [eventhub] AS eventhub
