#!/bin/bash
# Stop hook for strayfiles-ping
# Reminds Claude to send a ping notification to the user

echo '{
  "decision": "continue",
  "systemMessage": "If the user asked to be notified when done, remember to send them a ping notification now."
}'
exit 0
