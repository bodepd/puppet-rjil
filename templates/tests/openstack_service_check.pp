#!/bin/bash

"sudo <%= @service %>-manage service list | grep '<%= @name %>.*<%= @node_name %>.*enabled.*:-)'"
