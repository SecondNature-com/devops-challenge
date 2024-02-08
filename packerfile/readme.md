To run this file. Use the following command:

1. packer init . 

2. packer fmt .

3. packer validate -var-file="values_pkrvars.hcl" .

4. packer build -var-file="values_pkrvars.hcl" .