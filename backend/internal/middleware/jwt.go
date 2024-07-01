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

func CheckRole(allowedRoles ...string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			user := c.Get("user").(*jwt.Token)
			claims := user.Claims.(*jwt.MapClaims)
			userRole := (*claims)["role"].(string)

			for _, role := range allowedRoles {
				if role == userRole {
					return next(c)
				}
			}

			return echo.NewHTTPError(http.StatusForbidden, "You do not have the necessary permissions to access this resource")
		}
	}
}
