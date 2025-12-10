package com.example.demo.infrastructure.adapter.in.web;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import reactor.core.publisher.Mono;

import java.util.Map;

@RestController
public class DebugController {

    @GetMapping("/debug/ping")
    public Mono<Map<String, String>> ping() {
        return Mono.just(Map.of("status", "alive", "message", "RestController works!"));
    }
}
