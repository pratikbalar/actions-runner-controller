variable "GO_VERSION" {
  default = "1.17"
}

target "_common" {
  args = {
    GO_VERSION = GO_VERSION
  }
}

target "image-local" {
  inherits = ["_common"]
  target = "full"
  output = ["type=docker"]
  tags = ["summerwind/actions-runner-controller:local"]
}

target "image-local-slim" {
  inherits = ["_common"]
  target = "slim"
  output = ["type=docker"]
  tags = ["summerwind/actions-runner-controller:local-slim"]
}

target "image-all" {
  inherits = ["_common"]
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}

target "artifact" {
  inherits = ["_common"]
  target = "artifact"
  output = ["./dist"]
}

target "artifact-slim" {
  inherits = ["_common"]
  target = "artifact-slim"
  output = ["./dist"]
}

target "artifact-all" {
  inherits = ["artifact-all"]
  platforms = [
    "linux/amd64",
    "linux/arm64",
  ]
}