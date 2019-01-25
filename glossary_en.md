# Agile terms

1. pivotal tracker: A collaborative tool that manages the project schedule when performing an agile project. It automatically calculates the speed of the team and automatically adjusts the workings of each iteration accordingly. concourse, and git. pivotaltracker.com
2. MVP: Minimun Viable Product, minimal feature set that can give value to customers. The purpose of the experiment is to improve the customer's feedback. The quality of MVP is also very important.
3. user story: the minimum unit of work for pair programming. Describe the purpose of the work centered on the user's advantage. As a <role>, I want <goal / desire> so that <benefit> Must specify a success condition when the job is finished.
4. epic: A group of user stories that can be used to distinguish between work priority and other work
5. icebox: A repository that manages user stories to be made. The priorities are not fixed and are managed by the PM.
6. backlog: set of prioritized user stories for this iteration
7. pair programming: one of the methods of agile methodology. By doing the same thing on the same computer, I have the purpose of making my decisions, the benefits of sharing / communicating high quality code and products, knowledge, and ultimately creating a sustainable organization.
8. persona: Represents the character of the role. developer, platform engineer, etc.

# Continuous build / distribution (CI / CD) related terms
1. control plane: A set of tools for automated management of multiple platforms deployed and operating in the cloud (Pivotal Cloud Foundry Platform, MySQL Platform, Pivotal Ops Manager, etc.). It mainly includes Jumpbox (work VM), concourse (CI / CD tool.course-ci.org), docker registry, S3 and git repo as needed.
https://docs.pivotal.io/pivotalcf/2-0/refarch/control.html#placement
2. jumpBox: A VM that acts as a single access point for the platform(PAS, Control-Plane) . http://bosh.io/docs/terminology/#jumpbox
3. BOSH: An open source tool for the development, deployment, and operation of large-scale distributed clusters utilizing the cloud. Key features include: 1) Directly control creation, deletion, and modification of resources such as VM, Disk, and Network through CPI (Cloud Provider Interface) provided by IaaS providers such as AWS, GCP, Azure, vmware and openstack Therefore, provisioning the cluster directly. 2) You can create a distribution of the software (platform package) that constitutes the cluster(BOSH release). http://bosh.io
4. CI / CD Pipeline: An automated workflow from the build-to-deployment stage of the software to a concourse or jenkins.
10. credhub: An open source encrypted repository tool created by pivotal. It is a key-value repository that can generate, store, and retrieve certificates, passwords, and so on. Concatenation with UAA (concourse, PAS) Stores authentication information managed by UAA to enhance security of platform data. You can enhance security by storing authentication information in conjunction with the developer's application. https://github.com/pivotal-cf/credhub-release
5. concourse: An open source persistent build / persistent distribution (CI / CD) tool created by Pivotal. The pipeline is managed as source code, so you can instantly create pipelines and manage change history anytime and anywhere. concourse-ci.org
6. BBL: Abbreviation of Bosh BootLoader, CLI tool for automatic network creation through jumpbox, bosh, terraform https://github.com/cloudfoundry/bosh-bootloader
7. BBR: Abbreviation for Bosh Backup and Restore. CLI tool for backing up and restoring BOSH deployment and BOSH director https://github.com/cloudfoundry-incubator/bosh-backup-and-restore



# Pivotal Cloud Foundry related terms

1. PCF Foundation: A cluster in which Pivotal Ops Manager (BOSH) is deployed to automate and manage the Pivotal Cloud Foundry platform. The PCF foundation is automatically installed and upgraded by the concourse pipeline.
2. Droplet: A name that refers to a container image for an application that is automatically generated inside PAS (Pivotal Application Service). It is automatically generated when an application is deployed using the cloud foundry command tool. cf push (http://cli.cloudfoundry.org/en-US/cf/push.html)
If the application's executable code (jar file for java, source code for python) is thrown to the platform, then the JVM and framework required for the application execution in Java can be called from within the PaaS platform, . Even if one of the components such as JVM, framework, and application is changed due to security patches etc., it can be reassembled at any time, so automation efficiency is improved and container image is automatically managed by the platform, .
3. domains: The service domain to be used by applications served on PAS (Pivotal Application Service), ex) shared-domain.example.com
Applications are automatically published and sub-domains are published. ex) myapp.shared-domain.example.com
4. managed service: A service provided by a third party that the user can use as a self-service through Pivotal Cloud Foundry's API
5. orgs: The logical space in which the development team can develop and deploy applications on the Pivotal Application Service (PAS), often mapped to organizational structures such as teams that co-develop services.
6. routes: A service address that is assigned to the sub-domain in domains and bound to the application. In a PAS (Pivotal Application Service), an application can have multiple routes and be self-serviceable. ex) myapp.shared-domain.example.com
7. service: A backend service that can be used by applications such as MySQL, Redis, and RabbitMQ. It is exposed to marketplace on PAS (Pivotal Application Service) and can create service instance with self-service. These services are created by bosh-release and are managed by the platform administrator.
8. service instance: An instance created from service. There are two self-service models: MySQL for PCF can create self-service-only schemas, users, and self-service independent MySQL clusters in a public MySQL cluster pre-built by the operator .
9. UAA: One of cloud foundry's projects, it is responsible for user authentication based on OAuth2 protocol (User Account Authentication)


# BOSH related terms
1. https://bosh.io/docs/terminology
2. BOSH RELEASE: A distribution of the software (platform package, configuration template) that makes up the cluster. It is created through bosh. http://bosh.io/docs/terminology/#release
3. stemcell: VM OS image + bosh agent http://bosh.io/docs/terminology/#stemcell
4. bosh deployment manifest: Configuration information for deploying bosh release http://bosh.io/docs/terminology/#manifest
5. bosh deployment: The cluster that bosh deployed using the stemcell + bosh release + bosh deployment manifest. Check with the bosh deployments command.
6. Errand: This is a job that executes only once when executing bosh deployment, for example deployment testcase, deployment compile, etc. http://bosh.io/docs/terminology/#errand
