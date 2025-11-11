/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "factories_config" {
  description = "Paths to data files."
  type = object({
    networking = string
  })
}

variable "context" {
  description = "Context from previous stages."
  type        = any
  default     = {}
}

variable "azure_peer_ip_0" {
  description = "The first IP address of the Azure VPN gateway."
  type        = string
  default     = "0.0.0.0"
}

variable "azure_peer_ip_1" {
  description = "The second IP address of the Azure VPN gateway."
  type        = string
  default     = "0.0.0.0"
}
