resource "aws_rds_cluster" "aurora-db-cluster" {
  cluster_identifier         		  = "${var.environment_name}-aurora-db-cluster"
  engine             				  = "aurora-mysql"
  engine_version                      = "5.7.mysql_aurora.2.03.2"
  master_username                     = "${var.rds_master_username}"
  master_password                     = "${var.rds_master_password}"
  port                                = 3306
  backup_retention_period			  = 5
  preferred_backup_window 			  = "07:00-09:00"
  apply_immediately                   = true
  db_subnet_group_name  			  = "${aws_db_subnet_group.data-subnet-group.name}"
  db_cluster_parameter_group_name     = "default.aurora-mysql5.7"
  skip_final_snapshot				  = true

  vpc_security_group_ids = [aws_security_group.inbound-mysql-from-app.id]

  tags = {
    Owner       = "Avillach_Lab"
    Environment = "development"
    Name        = "FISMA Terraform Playground - RDS Aurora Cluster"
  }  
}

resource "aws_rds_cluster_instance" "aurora-cluster-instance" { 
  count						   = 1
  identifier         		   = "${var.environment_name}-aurora-instance-${count.index}"
  cluster_identifier           = "${aws_rds_cluster.aurora-db-cluster.id}"
  db_subnet_group_name  	   = "${aws_db_subnet_group.data-subnet-group.name}"
  engine                       = "aurora-mysql"
  engine_version               = "5.7.mysql_aurora.2.03.2"
  instance_class               = "db.t2.small"
  apply_immediately            = true 
  db_parameter_group_name	   = "default.aurora-mysql5.7"
  
  tags = {
    Owner       = "Avillach_Lab"
    Environment = "development"
    Name        = "FISMA Terraform Playground - RDS Aurora DB Instance - ${count.index}"
  }  
}