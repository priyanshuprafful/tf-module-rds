resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier      = "${var.env}-rds"
  engine                  = var.engine
  engine_version          = var.engine_version
  # availability_zones      = ["us-west-2a", "us-west-2b", "us-west-2c"]
  # do not need az as we are going to provide subnet group name
  database_name           = var.database_name
  master_username         = data.aws_ssm_parameter.user.value
  master_password         = data.aws_ssm_parameter.pass.value
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  db_subnet_group_name    = aws_db_subnet_group.subnet_group.name
  vpc_security_group_ids = [aws_security_group.main.id]
  skip_final_snapshot = true
#  final_snapshot_identifier = true
  tags = merge(
    var.tags ,
    { Name = "${var.env}-rds"}
  )
}

resource "aws_security_group" "main" {
  name = "RDS-${var.env}"
  description = "RDS-${var.env}-description"
  vpc_id = var.vpc_id


  ingress {
    description = "RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = var.allow_subnets
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(
    var.tags ,
    { Name = "RDS-${var.env}"}
  )

}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.no_of_instances
  identifier         = "${var.env}-rds-${count.index}"
  cluster_identifier = aws_rds_cluster.rds_cluster.id
  instance_class     = var.instance_class
  engine             = var.engine
  engine_version      = var.engine_version



}

resource "aws_db_subnet_group" "subnet_group" {
  name = "${var.env}-db"
  subnet_ids = var.subnet_ids
  tags = merge(
    var.tags ,
    { Name = "${var.env}-subnet-group"}
  )
}

resource "aws_ssm_parameter" "rds_endpoint" {
  name = "${var.env}.rds.endpoint"
  type = "String"
  value = aws_rds_cluster.rds_cluster.endpoint
}