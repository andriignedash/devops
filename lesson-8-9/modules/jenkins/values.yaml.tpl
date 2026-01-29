controller:
  serviceType: ${service_type}
  
  installPlugins:
    - kubernetes
    - workflow-aggregator
    - git
    - configuration-as-code
    - credentials
    - github
    - pipeline-utility-steps
    - job-dsl
  
  installLatestPlugins: true
  installLatestSpecifiedPlugins: true
  
  serviceAccountName: jenkins
  
  JCasC:
    defaultConfig: true
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: "Jenkins for Lesson 8-9: CI/CD with Kaniko, ECR, GitOps"
      
      kubernetes-cloud: |
        jenkins:
          clouds:
            - kubernetes:
                name: "kubernetes"
                serverUrl: "https://kubernetes.default"
                namespace: "${namespace}"
                jenkinsUrl: "http://jenkins.${namespace}.svc.cluster.local:8080"
                jenkinsTunnel: "jenkins-agent.${namespace}.svc.cluster.local:50000"
                templates:
                  - name: "kaniko"
                    label: "kaniko"
                    namespace: "${namespace}"
                    serviceAccount: "jenkins"
                    containers:
                      - name: "kaniko"
                        image: "gcr.io/kaniko-project/executor:v1.23.2-debug"
                        command: "/busybox/cat"
                        ttyEnabled: true
                        workingDir: "/home/jenkins/agent"
                        envVars:
                          - envVar:
                              key: "DOCKER_CONFIG"
                              value: "/kaniko/.docker"
                          - envVar:
                              key: "PATH"
                              value: "/usr/local/bin:/kaniko:/busybox:/tools"
                      - name: "git"
                        image: "alpine/git:latest"
                        command: "/bin/cat"
                        ttyEnabled: true
                        workingDir: "/home/jenkins/agent"
                    volumes:
                      - emptyDirVolume:
                          mountPath: "/home/jenkins/agent"
                          memory: false
                      - emptyDirVolume:
                          mountPath: "/kaniko/.docker"
                          memory: false
                      - emptyDirVolume:
                          mountPath: "/tools"
                          memory: false
                    yaml: |
                      spec:
                        initContainers:
                        - name: ecr-credential-helper
                          image: amazon/aws-cli:latest
                          command:
                          - /bin/sh
                          - -c
                          - |
                            curl -Lo /tools/docker-credential-ecr-login https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/0.7.1/linux-amd64/docker-credential-ecr-login
                            chmod +x /tools/docker-credential-ecr-login
                          volumeMounts:
                          - name: tools
                            mountPath: /tools
                        containers:
                        - name: kaniko
                          resources:
                            requests:
                              cpu: 500m
                              memory: 1Gi
                            limits:
                              cpu: 1000m
                              memory: 2Gi
                          volumeMounts:
                          - name: tools
                            mountPath: /tools
                        - name: git
                          resources:
                            requests:
                              cpu: 100m
                              memory: 128Mi
                            limits:
                              cpu: 200m
                              memory: 256Mi
                        volumes:
                        - name: tools
                          emptyDir: {}

  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 4Gi

persistence:
  enabled: true
  size: 10Gi
  storageClass: "gp2"

serviceAccount:
  create: false
  name: jenkins

agent:
  enabled: false
