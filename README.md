# Bibman

This is a bibliography managing tool.

## Requirements

* OCaml (4.00.1 or later) and the following libraries **Recommend 4.05 < version < 4.08.0**
  * batteries
  * pgocaml **Recommend 3.2**
  * pgocaml.syntax **Recommend 3.2**
  * cryptokit
  * yojson
  * config-file
  * netstring
  * netcgi2
  * pcre
  * text
* OMake
* PostgreSQL

## INSTALLATION

1. Create database and tables whose schemas are written in
   `config/database.schema`

3. Edit `config/configure.ml.example` and `script/DB_config.om.example` to be
   appropriate in your system

2. Copy
   1. `config/configure.ml.example` to `config/configure.ml`
   2. `script/DB_config.om.example` to `script/DB_config.om`

3. (Option.) Create static/tosho.tex

3. Type `omake
