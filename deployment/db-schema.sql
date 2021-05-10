CREATE TABLE METRICS
(
    username               VARCHAR(255),
    acceleration_x         FLOAT(6),
    acceleration_y         FLOAT(6),
    acceleration_z         FLOAT(6),
    acceleration_magnitude FLOAT(6),
    created_at             DATETIME DEFAULT CURRENT_TIMESTAMP
);
