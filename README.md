# panw-cspm-pov

This is a simple Terraform configuration file that will deploy a public EC2 instance with SSH port 22 exposed to the Internet, and a S3 bucket 
that is publicly exposed too. This deployment is used to test some Prisma Cloud use cases, and shouldn't be used in a production environment.

The only required input is the SSH key pair name you want to use to remotely connect to your instance.
