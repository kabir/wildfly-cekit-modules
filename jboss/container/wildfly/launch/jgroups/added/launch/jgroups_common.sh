#!/bin/sh

JGROUPS_PROTOCOL_ADDS="/tmp/jgroups-protocol-adds"


configure_protocol_cli_helper() {
  local params=("${@}")
  local stack=${params[0]}
  local protocol=${params[1]}
  local result
  IFS= read -rd '' result <<- EOF

    if (outcome == success) of /subsystem=jgroups/stack="${stack}"/protocol="${protocol}":read-resource
        echo Cannot configure jgroups '${protocol}' protocol under '${stack}' stack. This protocol is already configured. >> \${error_file}
        quit
    end-if

    if (outcome != success) of /subsystem=jgroups/stack="${stack}"/protocol="${protocol}":read-resource
        batch
EOF
  # removes the latest new line added by read builtin command
  result=$(echo -n "${result}")

  # starts in 2, since 0 and 1 are arguments
  for ((j=2; j<${#params[@]}; ++j)); do
    result="${result}
            ${params[j]}"
  done

  IFS= read -r -d '' result <<- EOF
        ${result}
       run-batch
    end-if
EOF


  echo "${result}"
}

init_protocol_add_operations_store() {
  rm -rf "${JGROUPS_PROTOCOL_ADDS}"
  mkdir "${JGROUPS_PROTOCOL_ADDS}"
}

# Store the protocol adds, so we can sort them later to avoid the add-indices interfering with each other
store_protocol_add_operation() {
  local stack="${1}"
  local index="${2}"
  local config="${3}"

  local stack_dir="${JGROUPS_PROTOCOL_ADDS}/${stack}"

  if [ ! -d "${stack_dir}" ]; then
    mkdir "${stack_dir}"
  fi

  local file_index
  file_index="$(find_next_name $stack_dir)"
  echo "${config}" >> "${stack_dir}/${file_index}.cfg"
  echo "${file_index}.cfg ${index}" >> "${stack_dir}/add-indices.txt"
}

order_protocol_add_operations_by_add_index_descending() {
  for dir_name in "${JGROUPS_PROTOCOL_ADDS}"/*/; do
    dir_name=$(basename "${dir_name}")
    local stack_dir="${JGROUPS_PROTOCOL_ADDS}/${dir_name}"
    local indices_file="${stack_dir}/add-indices.txt"
    local sorted_configs="${stack_dir}/sorted_configs.txt"

    if [ -f "${sorted_configs}" ]; then
      # The other script has done this
      return
    fi

    # Sort them in descending add-index, so that the add-indices don't interfer with each other while adding them
    sort -k 2 --numeric-sort -r ${indices_file} | awk '{print $1}' >> ${sorted_configs}

    while read -r line ; do
      cat "${stack_dir}/${line}" >> "${CLI_SCRIPT_FILE}"
    done < "${sorted_configs}"
  done
}

find_next_name() {
  local dir="${1}"

  local max
  max=0
  for filename in "${dir}"/*; do
    filename=$(basename "${filename}" ".cfg")
    if [[ "${filename}" -gt "${max}" ]]; then
      max="${filename}"
    fi
  done

  max=$((max + 1))
  echo "${max}"
}

