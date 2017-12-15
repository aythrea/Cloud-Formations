include:
  - users

brubble-key:
  ssh_auth.present:
    - user: brubble
    - source: salt://sshkeys/brubble.pub
    - config: /%h/.ssh/authorized_keys
    - require:
      - sls: users