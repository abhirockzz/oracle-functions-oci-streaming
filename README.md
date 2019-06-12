# Oracle Functions + OCI Streaming Service

This is an example which shows how you can invoke [Oracle Cloud Infrastructure Streaming Service](https://docs.cloud.oracle.com/iaas/Content/Streaming/Concepts/streamingoverview.htm) from Oracle Functions. A Java function acts as a producer and pushes messages to the Streaming Service using APIs in the [OCI Java SDK](https://docs.cloud.oracle.com/iaas/Content/API/SDKDocs/javasdk.htm).

A custom [Dockerfile](Dockerfile) is used to build the function. The Java FDK Docker image is used as the base along with the parts you want to customize i.e. in this specific case, the Dockerfile is modified 

- to download the OCI Java SDK JAR file from GitHub (since its currently not available via Maven), and
- copy the OCI private key inside the function Docker container

## Pre-requisites

- Streaming Service: You need create a Stream - please refer to the [details in the documentation](https://docs.cloud.oracle.com/iaas/Content/Streaming/Tasks/managingstreams.htm). You also need to ensure that the user account which you configure in the application (details to follow) have the required privileges to execute stream list and publish operations. If not, you might see `404` (authorization related) errors while invoking the function. Please refer to the [IAM Policies section in the documentation](https://docs.cloud.oracle.com/iaas/Content/Identity/Reference/streamingpolicyreference.htm) for further details
- Ensure you are using the latest version of the Fn CLI. To update simply run the following command - `curl -LSs https://raw.githubusercontent.com/fnproject/cli/master/install | sh`
- Oracle Functions: Configure the Oracle Functions service along with your development environment and switch to the correct Fn context using `fn use context <context-name>` 

Last but not the least, clone (`git clone https://github.com/abhirockzz/oracle-functions-oci-streaming`) or download this repository before proceeding further

## Create an application

Create an application with required configuration

`fn create app --annotation oracle.com/oci/subnetIds='["<OCI_SUBNET_OCIDs>"]' --config TENANCY=<TENANCY_OCID> --config USER=<USER_OCID --config FINGERPRINT=<PUBLIC_KEY_FINGERPRINT> --config PASSPHRASE=<PASSPHRASE> --config REGION=<OCI_REGION> fn-streaming-app`

Summary of the configuration parameters

- `OCI_SUBNET_OCIDs` - the OCID(s) of the subnet where you want your functions to be deployed
- `TENANCY` - OCID of your tenancy
- `USER` - OCID of the user which will be used to execute stream list and push operations
- `FINGERPRINT` - public key fingerprint of the user
- `PASSPHRASE` - passphrase of the private key
- `REGION` - Streaming Service region

For e.g.

`fn create app --annotation oracle.com/oci/subnetIds='["ocid1.subnet.oc1.phx.aaaaaaaabrg4uf2uzc3ni4jkz5vhqwprofmlmo7mpumnuddd7iandsfoobar"]' --config TENANCY=ocid1.tenancy.oc1..aaaaaaaaydrjm77otncda2xn7qtv7l3hqnd3zxn2u6siwdhniibwfvfoobar --config USER=ocid1.user.oc1..aaaaaaaavz5efq7jwjjipbvm536plgylg7rfr53obvtghpi2vbg3qyfoobar --config FINGERPRINT=42:42:5f:44:ca:a1:2e:58:d2:63:6a:af:52:d5:3d:42 --config PASSPHRASE=4242 --config REGION=us-phoenix-1 fn-streaming-app`

## Deploy the function

Change into the top level directory - `cd oracle-functions-oci-streaming`

Note: Before deploying the function, please copy your OCI private key file into the folder

To deploy

`fn -v deploy --build-arg PRIVATE_KEY_NAME=<PRIVATE_KEY_NAME> --app fn-streaming-app` 

> `PRIVATE_KEY_NAME` is the name of the private key (`.pem`) file

e.g. 

`fn -v deploy --build-arg PRIVATE_KEY_NAME=oci_private_key.pem --app fn-streaming-app`

This example uses version [`1.4.0`](https://github.com/oracle/oci-java-sdk/releases/tag/v1.4.0) of the OCI Java SDK by default. If you want wish to use a different version (see [releases](https://github.com/oracle/oci-java-sdk/releases)), you should make sure

- to add `--build-arg OCI_JAVA_SDK_VERSION=<required_version>` to the `fn deploy` command
- and also, update the version in `pom.xml`(s) of all the functions

		<dependency>
			<groupId>com.oracle.oci.sdk</groupId>
			<artifactId>oci-java-sdk</artifactId>
			<version>required_version</version>
		</dependency>

e.g. if you want to use SDK version `1.4.1`

`fn -v deploy --build-arg PRIVATE_KEY_NAME=oci_private_key.pem --build-arg OCI_JAVA_SDK_VERSION=1.4.1 --app fn-streaming-app`
 
### Sanity check

Run `fn inspect app fn-streaming-app` to check your app (and its config) and `fn list functions fn-streaming-app` to check associated function

## Testing

The function expects a payload with the following info - compartment OCID (where stream exists), stream name, `key` (String) and a `value` (String)

`echo -n '{"streamName":"test-stream", "compartmentOCID":"ocid1.compartment.oc1..aaaaaaaaokbzj2jn3hf5kwdwqoxl2dq7u54p3tsmxrjd7s3uu7x23tfoobar","key":"hello","value":"world"}' | fn invoke fn-streaming-app streaming-producer`

If successful, you should get an output similar to this

`Message pushed to offset 42 in partition 3`