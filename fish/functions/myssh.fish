function myssh -d "kinit then ssh with relaxed host key checking"
    /usr/bin/kinit -kt ~/.ssh/keytab zhangxingrui.leo@BYTEDANCE.COM
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $argv
end
