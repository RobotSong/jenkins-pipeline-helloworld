
// jenkins slave 执行流水线任务
timeout(time: 600, unit: 'SECONDS') {
    try{
        // 代理名称，填写系统设置中设置的 Cloud 中 Template 模板的 label
        def label = "jnlp-agent"
        podTemplate(label: label,cloud: 'kubernetes' ){
            node (label) {
                stage('Git阶段'){
                    echo "Git 阶段"
                    git branch: "master" ,changelog: true , url: "https://gogs.gxsgys.com/chenyongguang/jenkins-pipeline-helloworld.git", credentialsId: "GitAccount"
                }
                stage('Maven阶段'){
                    echo "Maven 阶段"
                    container('maven') {
                        //这里引用上面设置的全局的 settings.xml 文件，根据其ID将其引入并创建该文件
                        configFileProvider([configFile(fileId: "fe7eb33e-2166-4f3c-96e9-66cd8cc123db", targetLocation: "settings.xml")]){
                            sh "mvn clean install -Dmaven.test.skip=true --settings settings.xml"
                        }
                    }
                }
                stage('Docker阶段'){
                    echo "Docker 阶段"
                    container('docker') {
                        // 读取pom参数
                        echo "读取 pom.xml 参数"
                        pom = readMavenPom file: './pom.xml'
                        // 设置镜像仓库地址
                        hub = "dockerhub.gxsgys.com"
                        // 设置仓库项目名
                        project_name = "jenkins"
                        echo "编译 Docker 镜像"
                        // 第二个参数为 凭据ID
                        docker.withRegistry("https://${hub}", "dockerhubAccount") {
                            echo "构建镜像"
                            // 设置推送到子定义仓库的 jenkins 项目下，并用pom里面设置的项目名与版本号打标签
                            def customImage = docker.build("${hub}/${project_name}/${pom.artifactId}:${pom.version}")
                            echo "推送镜像"
                            customImage.push()
                            echo "获取镜像的sha256"
                            // 设置环境变量名称
                            env.IMAGES_SHA = "${hub}/${project_name}/${pom.artifactId}:${pom.version}"
                            echo "images name: $IMAGES_SHA"
                            // 获取远程镜像仓库中的 sha256 的值
                            def hubSha = "${sh(script: 'docker inspect $IMAGES_SHA -f \'{{index .RepoDigests 0}}\'', returnStdout: true).trim()}"
                            // 读取 yaml 文件
                            def deploy = readYaml file: './deploy-demo.yaml'
                            // 设置镜像 为 sha256 值，以便更新
                            deploy.spec.template.spec.containers[0].image = hubSha
                            // 先删除文件
                            sh 'rm -f deploy.yaml'
                            writeYaml file: 'deploy.yaml', data: deploy
                            echo "删除镜像"
                            sh "docker rmi ${hub}/${project_name}/${pom.artifactId}:${pom.version}"
                        }
                    }
                }
                stage('kubernetes部署阶段'){
                    container('helm-kubectl') {
                        echo "join kubernetes cluster"
                        withKubeConfig([credentialsId: "kubernetes-token", serverUrl: "https://kubernetes.default.svc.cluster.local"]) {
                            // 使用 kubectl 命令部署
                            echo "use kubectl apply deploy "
                            sh "kubectl apply -f deploy.yaml"
                        }
                    }
                }
            }
        }
    }catch(Exception e) {
        currentBuild.result = "FAILURE"
    }finally {
        // 获取执行状态
        def currResult = currentBuild.result ?: 'SUCCESS' 
        // 判断执行任务状态，根据不同状态发送邮件
        stage('email'){
            if (currResult == 'SUCCESS') {
                echo "发送成功邮件"
//                 emailext(subject: '任务执行成功',to: '3*****7@qq.com',body: '''任务已经成功构建完成...''')
            }else {
                echo "发送失败邮件"
//                 emailext(subject: '任务执行失败',to: '3*****7@qq.com',body: '''任务执行失败构建失败...''')
            }
        }
    }
}