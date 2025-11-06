inception/
├── Makefile
├── srcs/
│   ├── docker-compose.yml
│   ├── requirements/
│   │   ├── nginx/
│   │   │   ├── Dockerfile
│   │   │   └── conf/
│   │   │       └── default.conf
│   │   ├── wordpress/
│   │   │   ├── Dockerfile
│   │   │   ├── tools/
│   │   │   │   └── setup.sh
│   │   │   └── wp-config.php
│   │   ├── mariadb/
│   │   │   ├── Dockerfile
│   │   │   └── tools/
│   │   │       └── setup.sh
│   │   └── bonus/        # (si lo pide el proyecto)
│   │       ├── adminer/
│   │       ├── redis/
│   │       └── ftp/
│   └── .env
└── data/
    ├── mariadb/
    └── wordpress/
