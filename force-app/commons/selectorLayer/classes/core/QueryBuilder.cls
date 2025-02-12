/**
* MIT License
*
* Copyright (c) 2019 Piotr Kożuchowski
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

/**
 * Very simple query builder used in Selector layer
 */
public inherited sharing class QueryBuilder {
    public Map<String, Object> boundVars = new Map<String, Object>();
    private Set<String> fields = new Set<String>();
    private String fromObject = '';
    private String orderBy = '';
    private String groupBy = '';
    private String havingConditions = '';
    private String whereConditions = '';
    private String limitQueryPart = '';
    private String offsetQueryPart = '';


    /**
     * Builds and returns SOQL query
     */
    public String toSOQL() {
        String fieldsQueryPart = 'SELECT ' + String.join(new List<String>(fields), ', ');

        String[] query = new String[]{
                fieldsQueryPart,
                fromObject,
                whereConditions,
                groupBy,
                havingConditions,
                orderBy,
                limitQueryPart,
                offsetQueryPart
        };

        return String.join(query, ' ').trim();
    }

    public QueryBuilder bindVariable(String name, Object value) {
        this.boundVars.put(name, value);
        return this;
    }

    public QueryBuilder bindVariables(Map<String, Object> boundVars) {
        this.boundVars.putAll(boundVars);
        return this;
    }

    public Map<String, Object> getVariables() {
        return this.boundVars;
    }

    public QueryBuilder addField(SObjectField field) {
        this.fields.add('' + field);
        return this;
    }

    public QueryBuilder addField(String field) {
        this.fields.add(field);
        return this;
    }

    public QueryBuilder addFields(SObjectField[] fields) {
        for (SObjectField sObjectField : fields) {
            this.fields.add('' + sObjectField);
        }
        return this;
    }

    public QueryBuilder addFields(String[] fields) {
        this.fields.addAll(fields);
        return this;
    }

    public QueryBuilder setFields(String[] fields) {
        this.fields = new Set<String>(fields);
        return this;
    }


    public QueryBuilder addSubquery(QueryBuilder subqueryBuilder) {
        String subQuery = String.join(
                new String[]{
                        '(', subqueryBuilder.toSOQL(), ')'
                }, ' ');

        this.fields.add(subQuery);
        return this;
    }

    public QueryBuilder addChildFields(List<SObjectField> fields, String relationshipField) {
        return addSubquery(new QueryBuilder()
                .addFields(fields)
                .fromObject(relationshipField)
        );
    }

    public QueryBuilder addChildFields(List<String> fields, String relationshipField) {
        return addSubquery(new QueryBuilder()
                .addFields(fields)
                .fromObject(relationshipField)
        );
    }

    public QueryBuilder addParentFields(List<SObjectField> fields, SObjectField relationshipField) {
        String relation = relationshipField.getDescribe().getRelationshipName() + '.';

        for (SObjectField field : fields) {
            addField(relation + field);
        }

        return this;
    }

    public QueryBuilder addParentFields(List<String> fields, SObjectField relationshipField) {
        String relation = relationshipField.getDescribe().getRelationshipName() + '.';

        for (String field : fields) {
            addField(relation + field);
        }

        return this;
    }

    public QueryBuilder fromObject(SObjectType fromObject) {
        return fromObject('' + fromObject);
    }

    public QueryBuilder fromObject(String fromObject) {
        this.fromObject = 'FROM ' + fromObject;
        return this;
    }


    public QueryBuilder setWhere(String condition) {
        this.whereConditions = 'WHERE ' + condition;
        return this;
    }

    public QueryBuilder setGroupBy(String groupBy) {
        this.groupBy = 'GROUP BY ' + groupBy;
        return this;
    }

    public QueryBuilder setHaving(String havingConditionExpression) {
        this.havingConditions = 'HAVING ' + havingConditionExpression;
        return this;
    }

    public QueryBuilder setOrderBy(String orderBy) {
        this.orderBy = 'ORDER BY ' + orderBy;
        return this;
    }

    public QueryBuilder setLimit(Integer limitOf) {
        this.limitQueryPart = 'LIMIT ' + limitOf;
        return this;
    }

    public QueryBuilder setOffset(Integer offsetOf) {
        this.offsetQueryPart = 'OFFSET ' + offsetOf;
        return this;
    }

    /**
     * Adds query criteria to query builder and binds variable
     */
    public void setQueryCriteria(List<QueryCriteria> criteria) {
        List<String> conditionStrings = new List<String>();

        for (Integer i = 0, size = criteria.size(); i < size; i++) {
            String valueBinding = 'value' + i;
            conditionStrings.add(criteria[i].toString(valueBinding));
            this.bindVariable(valueBinding, criteria[i].value);
        }

        if (!conditionStrings.isEmpty()) {
            this.setWhere(String.join(conditionStrings, ' AND '));
        }
    }
}