#!/bin/bash

ps --no-header -u $USER -eo cputimes | awk '$1 > 4 {print $0;}'
