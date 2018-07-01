/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.wso2.apimgt.gateway.cli.model.rest;

import java.util.ArrayList;
import java.util.List;

/**
 * Class to represent a list of endpoint classified with production or sandbox URL type
 * 
 */
public class EndpointList {
    private EndpointUrlTypeEnum endpointUrlType;
    private List<Endpoint> endpoints = new ArrayList<>();

    public EndpointList(EndpointUrlTypeEnum type) {
        this.endpointUrlType = type;
    }

    public void setEndpoints(List<Endpoint> endpoints) {
        this.endpoints = endpoints;
    }

    public List<Endpoint> getEndpoints() {
        return endpoints;
    }

    public EndpointUrlTypeEnum getEndpointUrlType() {
        return endpointUrlType;
    }

    public void setEndpointUrlType(EndpointUrlTypeEnum endpointUrlType) {
        this.endpointUrlType = endpointUrlType;
    }
    
    public void addEndpoint(Endpoint endpoint) {
        endpoints.add(endpoint);
    }
}
