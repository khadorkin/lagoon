# Install Lagoon on OpenShift

Lagoon is not only capable to deploy into OpenShift, it actually runs in OpenShift. This creates the just tiny chicken-egg problem of how to install Lagoon on an OpenShift when there is no Lagoon yet.

Luckily we can use the local development environment to kickstart another Lagoon in any OpenShift, running somewhere in the world.

This process consists of 3 main stages, which are in short:

1. Configure existing OpenShift
2. Configure and connect local Lagoon with OpenShift
3. Deploy!
4. Configure Installed Lagoon

### Configure existing OpenShift

Hint: This also works with the OpenShift provided via MiniShift that can be started via `make openshift`.

In order to create resources inside OpenShift and push into the OpenShift Registry, Lagoon needs a Service Account within OpenShift \([read more about Service Accounts](https://docs.openshift.org/latest/dev_guide/service_accounts.html)\).

Technically Lagoon can use any Service Account and also needs no admin permissions, the only requirement is that the `self-provisioner` role is given to the Service Account.

In this example we create the Service Account `lagoon` in the OpenShift Project `default`.

1. Login into OpenShift as an Admin \(we assume that you have the oc cli tools already installed. If not, please see [here](https://docs.openshift.org/latest/cli_reference/get_started_cli.html#cli-reference-get-started-cli)\)

        oc login <openshift console>

2. Switch to the project default

        oc project default

3. Create Service Account `lagoon`.

        oc create serviceaccount lagoon

4. Describe lagoon \(we are interested in the first token\):

        oc describe serviceaccount lagoon

   example output:

        $ oc describe serviceaccount lagoon

        Name:		lagoon
        Namespace:	default
        Labels:		none;
        Annotations:	none;
        Image pull secrets:	lagoon-dockercfg-9q303

        Mountable secrets: 	lagoon-token-kvlv0
                              lagoon-dockercfg-9q303

        Tokens:            	lagoon-token-dkgwz
                              lagoon-token-kvlv0

5. Describe first token \(token are random generated, so yours will probably have another name\)

        oc describe secret lagoon-token-dkgwz

  example:

        Name:		lagoon-token-dkgwz

        Namespace:	default

        Labels:		&lt;none&gt;

        Annotations:	kubernetes.io/created-by=openshift.io/create-dockercfg-secrets
            kubernetes.io/service-account.name=lagoon
            kubernetes.io/service-account.uid=190342fc-99db-11e7-8e14-005056a1ae62

        Type:	kubernetes.io/service-account-token

        Data
        ====

        service-ca.crt:	2186 bytes

        token:		eyJhbGciOiJdfasdfNiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImxhZ29vbi10b2tlbi1kadasdfasdfasfV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJsYWdvb24iLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiIxOTA3NDlmYy05OWRiLTExZTctOGUxNC0wMDUwNTZhMWFlNjIiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6ZGVmYXVsdDpsYWdvb24ifQ.TD6zFNtxgSzpQV3IpF5uXDm96XWUqseMqxabPA3cLh9V5qrqoolJ73ZW3a8lx2klzTY20XDV4HpiTIMuqayjrljkc46\_JaWpkPwsDLl61jQdldVrO7PtAXZ-UD4AgDqVfchLhObDn1azlkudohYPtPvYsh8Qv8F1RPWQTpMaFywSLEza8MmrJWrnTCZ6d9V48Duzsmu5Jn2luS8NgmAN2375l5vYYD2fA4CLOUuOqBFrGjQasdfasdffq3np5ZsBMlg0piOREJEwul7hKfPxxMEblHZw7VZUvMleod9jCQmnwrrr5h8rprRV5wfHmpTFiC5JPV6UZGhA\_2gjOVw

        ca.crt:		1070 bytes

        namespace:	7 bytes

6. We are interested in the `token`, keep that for now somewhere safe.

7. Add Service Account `lagoon` to cluster role self-provisioner \(this will allow lagoon to create new projects in OpenShift\)

        oc -n default adm policy add-cluster-role-to-user self-provisioner -z lagoon
        oc -n default adm policy add-cluster-role-to-user system:build-strategy-custom -z lagoon

8. Create docker-host which will be used by the builds for docker layer caching (if you run that with a local OpenShift started via `make openshift`, this step is already done for you)

        oc -n default create serviceaccount docker-host
        oc -n default adm policy add-scc-to-user privileged -z docker-host
        oc -n default create -f openshift-setup/docker-host.yaml

### Configure and connect local Lagoon with OpenShift

In order to use a local Lagoon to deploy itself on an OpenShift, we need a subset of Lagoon running locally. We need to tech this local Lagoon how to connect to the OpenShift:

1. Edit `lagoon` inside local-dev/api-data/api-data.sql, in the `INSERT INTO openshift` section:
   1. `[replace me with OpenShift console URL]` - The URL to the OpenShift Console, without `console` at the end.
   2. `[replace me with OpenShift Token]` - The token of the lagoon service account that you created earlier

2. Build required Images and start services:

        make lagoon-kickstart

   This will do the following:
      1. Build all required Lagoon service Images (this can take a while)
      2. Start all required Lagoon services
      3. Wait 30 secs for all services to fully start
      4. Trigger a deployment of the `lagoon` sitegroup that you edited further, which will cause your local lagoon to connect to the defined OpenShift and trigger a new deployment
      5. Show the logs of all Local Lagoon Services

3. As soon as you see messages like `Build lagoon-1 running` in the logs it's time to connect to your OpenShift and check the build. The URL you will use for that depends on your system, but it's most probably the same as in `openshift.console`. Then you should see a new OpenShift Project called `[lagoon] develop` and in there a `Build` that is running. On a local OpenShift you can find that under https://192.168.99.100:8443/console/project/lagoon-develop/browse/builds/lagoon?tab=history. If you see the Build running check the logs and see how the deployment system does it's magic! This is your very first Lagoon deployment running! 🎉 Congrats!

    Short background on what is actually happening here:

    Your local running Lagoon (inside docker-compose) received a deploy command for a sitegroup called `lagoon` that you configured. In this SiteGroup it is defined to which OpenShift that should be deployed (one single Lagoon can deploy into multiple OpenShifts all around the world). So the local running Lagoon service `openshiftBuildDeploy` connects to this OpenShift and creates a new project, some needed configurations (ServiceAccounts, BuildConfigs, etc.) and triggers a new Build. This Build will run and deploy another Lagoon within the OpenShift it runs.

4. As soon as the build is done, go to the `Application > Deployments` section of the OpenShift Project and you should see all the Lagoon Deployment Configs deployed and running. Also go to `Application > Routes` and click on the generated route for `rest2tasks` (for a local OpenShift this will be http://rest2tasks-lagoon-develop.192.168.99.100.xip.io/), if you get `welcome to rest2tasks` as result, you did everything correct, bravo!

### Configure Installed Lagoon

We have now a fully running Lagoon. Now it's time to configure the first project inside of it. This happens via the GraphQL API of Lagoon, and in order to use that one, we need JWT (JSON Web Token) that allows us to use the GraphQL API as admin.

#### Connect to GraphQL API

To generate such token, open the terminal of the `auth-ssh` pod (you can either do that via the OpenShift UI or via `oc rsh`) and run:

        ./create_jwt.sh

This will return you with a long string, which is the jwt token.

We also need the URL of the API Endpoint, you can find that on the "Routes" of the OpenShift UI or via `oc xxxx`

Now we need a GraphQL client, technically this is just HTTP, but there is a nice UI that allows you to write GraphQL requests with autocomplete. Download, install and start it.

Enter the API Endpoint URL that we learned from before in `GraphQL Endpoint` and suffix it with `/graphql` (important!). Then click on "Edit HTTP Headers" and add a new Header:
- "Header name": `Authorization`
- "Header value": `Bearer [jwt token]` (make sure that the jwt token has no spaces, as this would not work)

Close the HTTP Header overlay (press ESC) and now we are ready to make the first GraphQL Request!

Enter this on the left window:

        {
          allProjects {
            name
          }
        }

And press the Play button (or press CTRL+ENTER). If all went well, you should see your first GraphQL response:

#### Create first Project

In order for Lagoon to deploy a project there is an example graphql in `create-project.gql`, which will create three API Objects:

1. `project` This is your git repository that should be deployed, it needs to contain a `.lagoon.yml` file so Lagoon knows what it should do.
2. `openshift` The OpenShift Cluster that Lagoon should use to deploy to. Yes Lagoon is not only capable to deploy into the OpenShift that it is running itself, but actually to any OpenShift anywhere in the world. We need to know the following infos for this to work:
        1. `name` - Unique identifier of the OpenShift
        2. `console_url` - URL of the OpenShift console (without any `/console` suffix)
        3. `token` - the token of the `lagoon` Service Account creted in this OpenShift (this is the same token that we also used during installation of Lagoon)
3. `customer` The customer of the project. Can be used for an actual customer (if you use Lagoon in a multi-customer setup), or just to group multiple projects together. `customer` will hold the SSH Private Key that Lagoon will use to clone the Git repository of the project (the private key needs to be in a single string, where new lines are replaced by `\n` - see an example in /local-dev/api-data/api-data.sql)


Just fill all the `[fill me]` you can find in `create-project.gql`, copy it into the GraphiQL Client, press play and if everything went well, you should get a response which shows you the name of the customer & openshift object and the full project object that just has been created.

Congrats again 🎉!

#### Connect
