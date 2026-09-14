# Data

`rawdata.csv` is the boiler record analysed in the paper: 4281 samples at a
constant 5-s interval (09:06:19–15:02:59, 5 h 57 min) from the plant's DCS
export, with no missing values. The first column is the clock time; the nine
process variables follow in this order:

| CSV column                 | Name used in the code  | Unit  |
|----------------------------|------------------------|-------|
| Inlet Gas Pressure (bar)   | `InletGasPressurebar`  | bar   |
| Inlet Gas Temp (°C)        | `InletGasTempC`        | °C    |
| Inlet Gas Flow (kg/h)      | `InletGasFlowkgh`      | kg/h  |
| Feed Water Temp (°C)       | `FeedWaterTempC`       | °C    |
| Steam Pressure (bar)       | `SteamPressurebar`     | bar   |
| Steam Temp (°C)            | `SteamTempC`           | °C    |
| Steam Flow (kg/h)          | `SteamFlowkgh`         | kg/h  |
| Exhaust Gas Oxygen (%)     | `ExhaustGasOxygen`     | %     |
| Exhaust Gas Temp (°C)      | `ExhaustGasTempC`      | °C    |

`src/data/load_record.m` reads the file, renames the columns as above, checks
for missing values and for a constant sampling interval, and returns a MATLAB
table. To run the pipeline on another record, supply a CSV with the same
column order (any header text) and set `cfg.sample_period_s` in
`config/default_config.m`; a `.mat` file holding a table named `dataset` with
the standard names is also accepted.
