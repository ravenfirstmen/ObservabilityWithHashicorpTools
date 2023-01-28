services {
    id = "grafana-agent"
	name = "grafana-agent"
    tags = ["grafana"]
    token = "${agent_server_token}"

    check = {
        id = "grafana-agent"
        name = "Health-check on grafana agent"
        http = "http://localhost:9090/-/healthy"
        method = "GET"
        disable_redirects = true
        interval = "10s"
        timeout = "5s"
    }
}
