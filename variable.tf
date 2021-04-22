# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
variable "do_token"  {
  type = string
  default= "nothingisdefault"
}
variable "k8s_servers"{
  type=list
  default=["nypv-k8mstr1","nypv-k8mstr2","nypv-k8wrkr1","nypv-k8wrkr2"]
}
variable "pvt_key" {}
