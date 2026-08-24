//
//  AppGroupStore.swift
//  WeekHabit
//

import Foundation
import SwiftData

/// Dónde vive la base y cómo la abre cada proceso.
///
/// Existe para que la app y la extensión del widget no puedan apuntar a contenedores
/// distintos: si cada una construyera su `ModelConfiguration` por su cuenta, un identificador
/// mal escrito no daría error — daría un widget que lee una base vacía y muestra cero
/// pendientes para siempre. Un solo lugar elimina esa clase de bug.
enum AppGroupStore {

    /// Debe coincidir con el App Group declarado en los entitlements de **los dos** targets.
    static let identifier = "group.com.valentino.WeekHabit"

    /// Configuración de la app: la única que puede escribir y migrar.
    static func appConfiguration(schema: Schema) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(identifier)
        )
    }

    /// Configuración de la extensión: de solo lectura.
    ///
    /// `allowsSave: false` no es decoración. El widget solo se asoma a leer lo que la app ya
    /// dejó listo, y dejarlo escrito en el tipo evita que una escritura accidental desde la
    /// extensión compita con la app por la misma base.
    static func readOnlyConfiguration(schema: Schema) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            allowsSave: false,
            groupContainer: .identifier(identifier)
        )
    }
}
