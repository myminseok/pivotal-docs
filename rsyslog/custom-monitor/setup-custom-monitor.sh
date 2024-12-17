#!/bin/bash

cat << EOF > /root/custom-monitor.sh
#!/bin/bash

## metric to be collected.
create_log_entry() {
    echo "\$(date --rfc-3339='second')"
    echo "# HIGH_CPU: \$(ps -eo %cpu,%mem,rss,pid,user,command | sort -r | head -3)"
    echo "# HIGH_MEMORY:  \$(ps aux --sort -rss | head -3)" 
    echo "# DISK usage: \$(df -h)"
    echo "# SSHD status: \$(service sshd status)"
    #echo "# JOURNALCTL_ERROR: \$(journalctl -p err -o verbose)"
}


while true; do
    log_record=\$(create_log_entry)
    echo "\${log_record}" | logger
    # collecting period.
    sleep 10 
done

EOF

chown root:root /root/custom-monitor.sh
chmod +x /root/custom-monitor.sh


cat << EOF > /etc/systemd/system/custom-monitor.service
[Unit]
Description=Custom
After=systemd-user-sessions.service

[Service]
User=root
Group=root
WorkingDirectory=/root
ExecStart=/root/custom-monitor.sh
Restart=on-failure
StandardOutput=/var/log/syslog

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable custom-monitor.service
systemctl start custom-monitor.service
