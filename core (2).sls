{% if grains['os_family'] == 'RedHat' %}
output_info:
    cmd.run:
        - name: mkdir //var//tmp/log; HOST_NAME=$(curl http://169.254.169.254/latest/meta-data/instance-id); HOST_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4); touch //var//tmp//log//$HOST_NAME.log; echo $HOST_NAME >> //var//tmp//log//salt-module-$HOST_NAME.log; $HOST_IP >> //var//tmp//log//salt-module-$HOST_NAME.log
        - onlyif: test -f //var//tmp//log//$HOST_NAME.log

upload_info
    cmd.run:
        - name: ACTALIAS=$(aws iam list-account-aliases | grep "infor"); ACCOUNT=$(echo $ACTALIAS | tr -d '"'); aws s3 cp //var//tmp//log s3://$ACCOUNT-cpq/cbeavers/chapter7 --recursive
        - require: output_info
        
{% elif grains['os_family'] == 'Windows' %}
create_log_dir:
    cmd.run: 
        - name: New-Item -path "c:\\" -name "logs" -itemtype "directory"
        - shell: powershell
        - unless: If ((test-path "c:\\logs") -eq $true) {exit 0} else {exit 1}

output_computername: 
    cmd.run:
        - name: $env:computername | out-file "c:\\logs\\salt-module-$env:computername.log" -force; (Get-NetIpAddress).IPv4Address | where ( $_ -inotlike '127.*') | out-file "c:\\logs\\salt-module-$env:computername.log" -append
        - shell: powershell
        - unless: if ((test-path "c:\\logs\\salt-module-$env:computername.log") -eq $true) {exit 0} else {exit 1}
        - require:
          - cmd: create_log_dir

output_computer_ip:
    cmd.run:
        - name: ((Get-NetIpAddress).IPv4Address | where { $_ -like '10.*'}) | out-file "c:\\logs\\salt-module-$env:computername.log" -append
        - shell: powershell
        - require:
          - cmd: output_computername

upload_info:
    cmd.run:
        - name: $actalias= get-iamaccountalias -profilename cpqade; write-s3object -bucketname $actalias-cpq -keyprefix cbeavers/chapter7 -Folder "C:\logs" -ProfileName cpqade
        - shell: powershell
        - require:
          - cmd: output_computer_ip

{% endif %}