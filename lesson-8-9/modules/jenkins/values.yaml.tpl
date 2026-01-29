controller:
  serviceType: ${service_type}
  
  installPlugins:
    - kubernetes:4253.v7700d91739e5
    - workflow-aggregator:596.v8c21c963d92d
    - git:5.2.2
    - configuration-as-code:1836.vccda_4a_122a_a_e
    - credentials:1371.vfee6b_095f0a_3
    - github:1.39.0
    - pipeline-utility-steps:2.16.2
    - job-dsl:1.87
    - blueocean:1.27.14
  
  serviceAccountName: jenkins
  
  JCasC:
    defaultConfig: true
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: "Jenkins для Lesson 8-9: CI/CD с Kaniko, ECR, GitOps"
      
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
                    volumes:
                      - emptyDirVolume:
                          mountPath: "/home/jenkins/agent"
                          memory: false
                      - emptyDirVolume:
                          mountPath: "/kaniko/.docker"
                          memory: false
                    yaml: |
                      spec:
                        containers:
                        - name: kaniko
                          resources:
                            requests:
                              cpu: 500m
                              memory: 1Gi
                            limits:
                              cpu: 1000m
                              memory: 2Gi

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
