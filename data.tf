 data "aws_availability_zones" "available" {
  state = "available"
}
/* 
output "name" {
  value = data.aws_availability_zones.available
}  */

data "aws_vpc" "default" {
  default = true
}