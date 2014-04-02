use mysql;
DELETE FROM user WHERE User='';
DELETE FROM user WHERE User='root' AND Host != 'localhost';
DROP DATABASE IF EXISTS test;
DELETE FROM db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
