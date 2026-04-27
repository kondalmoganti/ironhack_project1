resource "aws_lb" "app_alb" {
  name               = "kondal-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_2.id
  ]
}

resource "aws_lb_target_group" "vote_tg" {
  name     = "vote-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group" "result_tg" {
  name     = "result-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_target_group_attachment" "vote_attach" {
  target_group_arn = aws_lb_target_group.vote_tg.arn
  target_id        = aws_instance.frontend.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "result_attach" {
  target_group_arn = aws_lb_target_group.result_tg.arn
  target_id        = aws_instance.frontend.id
  port             = 8081
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vote_tg.arn
  }
}

resource "aws_lb_listener_rule" "result_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.result_tg.arn
  }

  condition {
    path_pattern {
      values = ["/result*"]
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = "arn:aws:acm:us-east-2:686699774218:certificate/3f9c477c-9f23-45d6-b370-495230a35c58"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vote_tg.arn
  }
}

resource "aws_lb_listener_rule" "https_result_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.result_tg.arn
  }

  condition {
    path_pattern {
      values = ["/result", "/result/*"]
    }
  }
}

resource "aws_route53_record" "root" {
  zone_id = "Z052188037AMQDOLG826S"
  name    = "kondal.online"
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

