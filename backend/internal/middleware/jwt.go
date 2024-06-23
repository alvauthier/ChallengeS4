package middleware

import (
	"net/http"
	"weezemaster/internal/config"

	"github.com/golang-jwt/jwt/v5"
	jwtMiddleware "github.com/labstack/echo-jwt/v4"
	"github.com/labstack/echo/v4"
)

func JWTMiddleware() echo.MiddlewareFunc {
	return jwtMiddleware.WithConfig(jwtMiddleware.Config{
		SigningKey:    config.SecretKey,
		SigningMethod: "HS256",
		NewClaimsFunc: func(c echo.Context) jwt.Claims {
			return new(jwt.MapClaims)
		},
		ErrorHandler: func(c echo.Context, err error) error {
			return echo.NewHTTPError(http.StatusUnauthorized, "Invalid or expired token")
		},
	})
}
