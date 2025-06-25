#!/bin/bash
set -e

host=mysql
user=xdmodapp
pass=ofbatgorWep0

if [ "$1" = "serve" ]
then
    echo "---> Starting SSSD on xdmod ..."
    # Sometimes on shutdown pid still exists, so delete it
    rm -f /var/run/sssd.pid
    /sbin/sssd --logger=stderr -d 2 -i 2>&1 &

    echo "---> Starting sshd on xdmod..."
    /usr/sbin/sshd -e

    echo "---> Starting the MUNGE Authentication service (munged) on xdmod ..."
    gosu munge /usr/sbin/munged

    echo "---> Starting sshd on xdmod..."
    /usr/sbin/sshd

    until echo "SELECT 1" | mysql -h $host -u$user -p$pass 2>&1 > /dev/null
    do
        echo "-- Waiting for database to become active ..."
        sleep 2
    done

    # Check if XDMoD is already initialized
    tables=$(mysql -u${user} -p${pass} --host ${host} -NB modw -e "SHOW TABLES" 2>/dev/null || echo "")
    if [[ -n "$tables" ]]; then
        echo "---> XDMoD already initialized, skipping setup"
        if [ -f "/xdmod/setup.sh" ]; then
            /xdmod/setup.sh
        fi
    else
        echo "---> Initializing XDMoD database..."
        
        # Initialize database schema
        echo "---> Creating database schema..."
        mysql -u${user} -p${pass} --host ${host} modw < /usr/share/xdmod/db/schema/modw.sql 2>/dev/null || true
        mysql -u${user} -p${pass} --host ${host} moddb < /usr/share/xdmod/db/schema/moddb.sql 2>/dev/null || true
        mysql -u${user} -p${pass} --host ${host} mod_logger < /usr/share/xdmod/db/schema/mod_logger.sql 2>/dev/null || true
        mysql -u${user} -p${pass} --host ${host} mod_shredder < /usr/share/xdmod/db/schema/mod_shredder.sql 2>/dev/null || true
        mysql -u${user} -p${pass} --host ${host} mod_hpcdb < /usr/share/xdmod/db/schema/mod_hpcdb.sql 2>/dev/null || true
        
        # Run ETL bootstrap
        echo "---> Running ETL bootstrap..."
        cd /usr/share/xdmod
        php tools/etl/etl_overseer.php -c /etc/xdmod/etl/etl.json -p ingest.bootstrap 2>/dev/null || true
        
        # Import hierarchy if file exists
        if [ -f "/srv/xdmod/hierarchy.csv" ]; then
            echo "---> Importing hierarchy..."
            sudo -u xdmod xdmod-import-csv -t hierarchy -i /srv/xdmod/hierarchy.csv 2>/dev/null || true
        fi
        
        # Create admin user
        echo "---> Creating admin user..."
        mysql -u${user} -p${pass} --host ${host} moddb -e "
        INSERT IGNORE INTO Users (id, username, email_address, first_name, last_name, time_created, time_last_updated, account_is_active, person_id, organization_id, field_of_science, user_type) 
        VALUES (1, 'admin', 'admin@localhost', 'Admin', 'User', NOW(), NOW(), 1, 1, 1, 1, 1);
        INSERT IGNORE INTO UserRoles (user_id, role_id) VALUES (1, 1);
        " 2>/dev/null || true
        
        echo "---> XDMoD initialization complete"
    fi
    
    # Ensure CORS setting for OnDemand integration
    sed -i 's%domains = ""%domains = "https://localhost:3443"%g' /etc/xdmod/portal_settings.ini 2>/dev/null || true
    
    echo "---> Starting php-fpm"
    mkdir -p /run/php-fpm
    php-fpm &

    echo "---> Starting HTTPD on xdmod..."
    # Sometimes on shutdown pid still exists, so delete it
    rm -f /var/run/httpd/httpd.pid
    
    # Start httpd in foreground
    exec /usr/sbin/httpd -DFOREGROUND
fi

exec "$@"
