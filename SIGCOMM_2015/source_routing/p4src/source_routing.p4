/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// TODO: define headers & header instances
header_type easy_route_t {
    fields{
        preamble: 64;
        num_valid: 32;
    }
}
header_type port_t {
    fields {
        port_id: 8;
    }
}

parser start {
    // TODO
    return select(current(0, 64)){
        0x0: parser_easy_route;
    }
}

header easy_route_t easy_route_hdr;
header port_t port;
parser parser_easy_route {
    extract(easy_route_hdr);
    extract(port);
    return ingress;
}



action _drop() {
    drop();
}

//table defination
table tb_drop {
    actions { _drop; }
    size: 0;
}

table tb_route {
    reads {
        port.port_id : exact;
    }
    actions {
        route;  //routing function, 
        _drop;  //invoked when no output port match 
    }
    size : 3;
}

action route() {
    modify_field(standard_metadata.egress_spec, port.port_id);
    // TODO: update your header
    remove_header(port);
}

control ingress {
    // TODO
    if(easy_route_hdr.num_valid == 0){
        apply(tb_drop);
    }
    else {
        apply(tb_route);
    }
}

control egress {
    // leave empty
}
