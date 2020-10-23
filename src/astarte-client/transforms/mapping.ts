/*
   This file is part of Astarte.

   Copyright 2020 Ispirata Srl

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

import { AstarteMapping } from '../models/Mapping';
import type { AstarteMappingDTO } from '../types';

export const fromAstarteMappingDTO = (dto: AstarteMappingDTO): AstarteMapping => {
  return new AstarteMapping({
    endpoint: dto.endpoint,
    type: dto.type,
    reliability: dto.reliability,
    retention: dto.retention,
    expiry: dto.expiry,
    databaseRetentionPolicy: dto.database_retention_policy,
    databaseRetentionTtl: dto.database_retention_ttl,
    allowUnset: dto.allow_unset,
    explicitTimestamp: dto.explicit_timestamp,
    description: dto.description,
    documentation: dto.doc,
  });
};

export const toAstarteMappingDTO = (obj: AstarteMapping): AstarteMappingDTO => {
  return {
    endpoint: obj.endpoint,
    type: obj.type,
    reliability: obj.reliability,
    retention: obj.retention,
    expiry: obj.expiry,
    database_retention_policy: obj.databaseRetentionPolicy,
    database_retention_ttl: obj.databaseRetentionTtl,
    allow_unset: obj.allowUnset,
    explicit_timestamp: obj.explicitTimestamp,
    description: obj.description,
    doc: obj.documentation,
  };
};
