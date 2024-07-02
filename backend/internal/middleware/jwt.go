package middleware

import (
	"fmt"
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
			token, ok := c.Get("user").(*jwt.Token)
			if !ok {
				return echo.NewHTTPError(http.StatusUnauthorized, "Invalid token")
			}

			claims, ok := token.Claims.(*jwt.MapClaims)
			if !ok || !token.Valid {
				return echo.NewHTTPError(http.StatusUnauthorized, "Invalid token claims")
			}
			// Débogage : afficher les claims
			fmt.Printf("Claims: %+v\n", claims)

			// Récupération du rôle de l'utilisateur depuis les claims
			userRole, ok := (*claims)["role"].(string)
			if !ok {
				return echo.NewHTTPError(http.StatusForbidden, "Role not found in token")
			}

			// Débogage : afficher le rôle de l'utilisateur
			fmt.Printf("User role: %s\n", userRole)

			// Vérification si le rôle de l'utilisateur est dans la liste des rôles autorisés
			for _, role := range allowedRoles {
				if role == userRole {
					return next(c)
				}
			}

			return echo.NewHTTPError(http.StatusForbidden, "You do not have the necessary permissions to access this resource")
		}
	}
}
