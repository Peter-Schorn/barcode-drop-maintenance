FROM swift:5.10-amazonlinux2

RUN yum -y install zip

# Build everything, with optimizations
RUN swift build -c release --static-swift-stdlib
