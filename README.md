# Employee profiles for internal services (HR) [![Build Status](https://travis-ci.org/hoopoe/tercomin.svg?branch=master)](https://travis-ci.org/hoopoe/tercomin)

Install Instructions: 
Please, install plugin into "~/redmine/plugins/tercomin"

rake redmine:plugins:migrate NAME=tercomin

Required:
2 redmine groups: "hr" and "lt-prj-tercomin-pm"
1 project id: "tercomin"

Extra:
rake redmine:tercomin:load_profiles (to load user profiles)

Demo: https://damp-thicket-8206.herokuapp.com
uid: ivan
pwd: password



