// Copyright 2019-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
// SmokeAWSModelGenerate.swift
// SmokeAWSModelGenerate
//

import Foundation
import ServiceModelCodeGeneration
import ServiceModelEntities
import CoralToJSONServiceModel
import ServiceModelGenerate

public struct SmokeAWSModelGenerate {
    
    public static func generateFromModel(
        modelFilePath: String,
        customizations: CodeGenerationCustomizations,
        applicationDescription: ApplicationDescription,
        modelOverride: ModelOverride?,
        signAllHeaders: Bool) throws -> CoralToJSONServiceModel {
            func generatorFunction(codeGenerator: ServiceModelCodeGenerator,
                                   serviceModel: CoralToJSONServiceModel) throws {
                try codeGenerator.generateFromCoralToJSONServiceModel(
                    coralToJSONServiceModel: serviceModel,
                    asyncAwaitAPIs: customizations.asyncAwaitAPIs,
                    signAllHeaders: signAllHeaders
                )
            }
        
            return try ServiceModelGenerate.generateFromModel(
                    modelFilePath: modelFilePath,
                    customizations: customizations,
                    applicationDescription: applicationDescription,
                    modelOverride: modelOverride,
                    generatorFunction: generatorFunction)
    }
}

extension ServiceModelCodeGenerator {
    
    func generateFromCoralToJSONServiceModel(
            coralToJSONServiceModel: CoralToJSONServiceModel,
            asyncAwaitAPIs: CodeGenFeatureStatus,
            signAllHeaders: Bool) throws {
        let awsClientAttributes = coralToJSONServiceModel.getAWSClientAttributes()
        
        let clientProtocolDelegate = ClientProtocolDelegate(
            baseName: applicationDescription.baseName,
            asyncAwaitAPIs: asyncAwaitAPIs)
        let mockClientDelegate = MockClientDelegate(
            baseName: applicationDescription.baseName,
            isThrowingMock: false,
            asyncAwaitAPIs: asyncAwaitAPIs)
        let throwingClientDelegate = MockClientDelegate(
            baseName: applicationDescription.baseName,
            isThrowingMock: true,
            asyncAwaitAPIs: asyncAwaitAPIs)
        let awsClientDelegate = AWSClientDelegate(
            baseName: applicationDescription.baseName,
            clientAttributes: awsClientAttributes,
            signAllHeaders: signAllHeaders,
            asyncAwaitAPIs: asyncAwaitAPIs)
        let awsModelErrorsDelegate = AWSModelErrorsDelegate(awsClientAttributes: awsClientAttributes)
        
        generateClient(delegate: clientProtocolDelegate, fileType: .clientImplementation)
        generateClient(delegate: mockClientDelegate, fileType: .clientImplementation)
        generateClient(delegate: throwingClientDelegate, fileType: .clientImplementation)
        generateClient(delegate: awsClientDelegate, fileType: .clientImplementation)
        generateClient(delegate: awsClientDelegate, fileType: .clientGenerator)
        generateModelOperationsEnum()
        generateOperationsReporting()
        generateInvocationsReporting()
        generateModelOperationClientInput()
        generateModelOperationClientOutput()
        generateModelStructures()
        generateModelTypes()
        generateModelErrors(delegate: awsModelErrorsDelegate)
        generateDefaultInstances(generationType: .internalTypes)
    }
}
