#!/bin/bash

check_memory_requirement() {
  local mem_needed=$1
  local project_name=${2:-"this project"}
  local mem_available=$(free -g | awk '/Mem:/ {print $2}')
  
  if [ "$mem_available" -lt "$mem_needed" ]; then
    echo "Build aborted: building $project_name requires ${mem_needed}GB RAM but only ${mem_available}GB available."
    return 1
  fi
  return 0
}