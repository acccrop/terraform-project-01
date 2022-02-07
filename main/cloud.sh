TF_ACTION=$1
ENVIRONMENT=$2
PARAMS=$3

export VAR_FILE="../workspaces/${ENVIRONMENT}/${ENVIRONMENT}.tfvars"


function terraform_config_generate {
  TERRAFORM_EXISTS=$(json2hcl -reverse < ${VAR_FILE} | jq -c '.terraform')

  if [ "$TERRAFORM_EXISTS" == 'null' ]; then
    return
  fi

  echo "terraform {" > terraform.tf

  TERRAFORM_CONFIG=$(json2hcl -reverse < ${VAR_FILE} | jq -c '.terraform[0]')
  TERRAFORM_CONFIG_REQUIRED_VERSION=$(echo $TERRAFORM_CONFIG | jq -r '.required_version')

  if [ "$TERRAFORM_CONFIG_REQUIRED_VERSION" != 'null' ]; then
    echo "required_version = \"$TERRAFORM_CONFIG_REQUIRED_VERSION\"" >> terraform.tf
  fi

  # LOADING BACKEND

  BACKEND_EXISTS=$(echo $TERRAFORM_CONFIG | jq -r '.backend')

  if [ "$BACKEND_EXISTS" != 'null' ]; then
    TERRAFORM_CONFIG_BACKEND_TYPE=$(echo $TERRAFORM_CONFIG | jq -r '.backend[0] | keys[0]')

    if [ "$TERRAFORM_CONFIG_BACKEND_TYPE" != '' ]; then
      echo "backend \"$TERRAFORM_CONFIG_BACKEND_TYPE\" {" >> terraform.tf

      TERRAFORM_CONFIG_BACKEND_CONFIG=$(echo $TERRAFORM_CONFIG | jq '.backend[0][.backend[0] | keys[0]][0]')
      TERRAFORM_CONFIG_BACKEND_CONFIG_KEYS=$(echo $TERRAFORM_CONFIG_BACKEND_CONFIG | jq 'keys')

      for KEY in $(echo $TERRAFORM_CONFIG_BACKEND_CONFIG_KEYS | jq -r '.[]'); do
        VALUE=$(echo $TERRAFORM_CONFIG_BACKEND_CONFIG | jq --arg KEY "$KEY" '.[$KEY]')
        if [[ ${VALUE:0:1} == '{' || ${VALUE:0:1} == '[' ]]; then
            echo "${KEY} {" >> terraform.tf
            VALUE_KEYS=$(echo $VALUE | jq '.[0] | keys')
            for KEY2 in $(echo $VALUE_KEYS | jq -r '.[]'); do
              VALUE2=$(echo $VALUE | jq --arg KEY2 "$KEY2" '.[0][$KEY2]')
              echo ${KEY2} = ${VALUE2} >> terraform.tf
            done
            echo "}" >> terraform.tf
        else
            echo ${KEY} = ${VALUE} >> terraform.tf
        fi
      done
      echo "}" >> terraform.tf
    fi
  fi

  
  # LOADING PROVIDER CONFIG

  PROVIDERS_EXISTS=$(echo $TERRAFORM_CONFIG | jq -r '.required_providers')
  if [ "$PROVIDERS_EXISTS" != 'null' ]; then
    PROVIDERS_CONFIG=$(echo $TERRAFORM_CONFIG | jq -c '.required_providers[0]')
    echo "required_providers {" >> terraform.tf

    for P in $(echo $PROVIDERS_CONFIG | jq -r 'keys | .[]'); do
      PROVIDER=$(echo $PROVIDERS_CONFIG | jq --arg PROVIDER "$P" '.[$PROVIDER]')
      if [[ ${PROVIDER:0:1} == '{' || ${PROVIDER:0:1} == '[' ]]; then
        PROVIDER=$(echo $PROVIDERS_CONFIG | jq --arg PROVIDER "$P" '.[$PROVIDER][0]')
        echo "$P = {" >> terraform.tf
        for KEY in $(echo $PROVIDER | jq -r 'keys | .[]'); do
          echo ${KEY} = $(echo $PROVIDER | jq --arg KEY "$KEY" '.[$KEY]') >> terraform.tf
        done
        echo "}" >> terraform.tf
      else
        echo "$P = $PROVIDER" >> terraform.tf
      fi
    done

    echo "}" >> terraform.tf

  fi

  # ENDING
  echo "}" >> terraform.tf
  terraform fmt -list=false terraform.tf
} 

terraform_config_generate

if [ "$TF_ACTION" = 'security-scan' ]; then
  tfsec . --tfvars-file="../workspaces/${ENVIRONMENT}/${ENVIRONMENT}.tfvars" ${PARAMS}
  checkov -d .

else 
  echo "Terraform action: ${TF_ACTION}"
  terraform ${TF_ACTION} -var-file="../workspaces/${ENVIRONMENT}/${ENVIRONMENT}.tfvars" ${PARAMS}
fi;