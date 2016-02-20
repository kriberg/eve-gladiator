{% set gladiator = salt["pillar.get"]("gladiator", {}) %}
{% set db = salt["pillar.get"]("postgres", {}) %}
{% set crest = salt["pillar.get"]("crest", {}) %}

include:
  - postgres

platform_dependencies:
  pkg.installed:
    - names:
      - git
      - libpq-dev
      - redis-server

dump_directory:
  file.directory:
    - name: /tmp/sde
    - makedirs: True
    - user: vagrant
    - group: vagrant

latest_postgresql_dump:
  file.managed:
    - name: /tmp/sde/postgres-latest.dmp.bz2
    - source: https://www.fuzzwork.co.uk/dump/postgres-latest.dmp.bz2
    - source_hash: https://www.fuzzwork.co.uk/dump/postgres-latest.dmp.bz2.md5
    - user: vagrant
    - group: vagrant
    - require:
      - file: dump_directory

delete_old_dump:
  cmd.wait:
    - name: 'rm postgres-latest.dmp'
    - cwd: '/tmp/sde'
    - onlyif: 'test -f /tmp/sde/postgres-latest.dmp'
    - watch:
      - file: latest_postgresql_dump

unpacked_dump:
  cmd.run:
    - name: 'bunzip2 -k postgres-latest.dmp.bz2'
    - cwd: '/tmp/sde'
    - onlyif: 'test ! -f postgres-latest.dmp'
    - user: vagrant
    - group: vagrant
    - shell: /bin/bash
    - require:
      - file: latest_postgresql_dump

import_sde:
  cmd.run:
    - name: 'pg_restore --role=vagrant -n public -O -j 4 -d bushido /tmp/sde/postgres-latest.dmp'
    - user: postgres
    - shell: /bin/bash
    - onlyif: 'test "$(psql -c "\d" bushido)" = "No relations found."'
    - require:
      - cmd: unpacked_dump

