# bug in bats with set -eu?
export BATS_TEST_SKIPPED=

# fake JBOSS_HOME
export JBOSS_HOME=$BATS_TEST_DIRNAME/../../../../../../test-common/

source ${BATS_TEST_DIRNAME}/../../../launch-config/os/added/launch/launch-common.sh
source ${BATS_TEST_DIRNAME}/../../os/node-name/added/launch/openshift-node-name.sh
source $JBOSS_HOME/logging.sh

# fake the logger so we don't have to deal with colors
export TEST_LOGGING_INCLUDE=$BATS_TEST_DIRNAME/../../../../../../test-common/logging.sh
export TEST_LAUNCH_INCLUDE=$BATS_TEST_DIRNAME/../../../launch-config/os/added/launch/launch-common.sh
export TEST_TX_DATASOURCE_INCLUDE=$BATS_TEST_DIRNAME/../added/launch/tx-datasource.sh

load $BATS_TEST_DIRNAME/../added/launch/datasource-common.sh

setup() {
  export CONFIG_FILE=${BATS_TMPDIR}/standalone-openshift.xml
}

teardown() {
  if [ -n "${CONFIG_FILE}" ] && [ -f "${CONFIG_FILE}" ]; then
    rm "${CONFIG_FILE}"
  fi
}

@test "Generate Datasource Common" {

  run generate_datasource_common "pool_nameVal" "jndi_nameVal" "usernameVal" "passwordVal" "hostVal" "portVal" "databasenameVal" \
    "checkerVal" "sorterVal" "driverVal" "servicenameVal" "jtaVal" "validateVal" "urlVal"
  echo ${result}
  echo "Result: ${result}"
  echo "Expected: ${expected}"
  [ "${result}" = "${expected}" ]
}

