resource "aws_glue_catalog_database" "athena" {
  name = "${var.service_name}_db"
}

resource "aws_glue_catalog_table" "athena" {
  name          = "${var.service_name}_logs"
  database_name = "${aws_glue_catalog_database.athena.name}"
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${var.service_name}-${var.workspace}-data-pipeline/log/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "jsonserde"
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"

      parameters = {
        "serialization.format" = "1"
      }
    }

    dynamic "columns" {
        for_each = "${var.columns}"

        content {
            name = "${columns.key}"
            type = "${columns.value}"
        }
    }
  }
    partition_keys {
        name = "year"
        type = "string"
    }
    partition_keys {
        name = "month"
        type = "string"
    }
    partition_keys {
        name = "day"
        type = "string"
    }
    partition_keys {
        name = "hour"
        type = "string"
    }
}