/**
 * generated by Xtext 2.12.0
 */
package tools.vitruv.dsls.mappings.mappingsLanguage;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Feature Condition</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link tools.vitruv.dsls.mappings.mappingsLanguage.FeatureCondition#getValueExpression <em>Value Expression</em>}</li>
 *   <li>{@link tools.vitruv.dsls.mappings.mappingsLanguage.FeatureCondition#isNegated <em>Negated</em>}</li>
 *   <li>{@link tools.vitruv.dsls.mappings.mappingsLanguage.FeatureCondition#getOperator <em>Operator</em>}</li>
 * </ul>
 *
 * @see tools.vitruv.dsls.mappings.mappingsLanguage.MappingsLanguagePackage#getFeatureCondition()
 * @model
 * @generated
 */
public interface FeatureCondition extends EnforceableCondition
{
  /**
   * Returns the value of the '<em><b>Value Expression</b></em>' containment reference.
   * <!-- begin-user-doc -->
   * <p>
   * If the meaning of the '<em>Value Expression</em>' containment reference isn't clear,
   * there really should be more of a description here...
   * </p>
   * <!-- end-user-doc -->
   * @return the value of the '<em>Value Expression</em>' containment reference.
   * @see #setValueExpression(ValueExpression)
   * @see tools.vitruv.dsls.mappings.mappingsLanguage.MappingsLanguagePackage#getFeatureCondition_ValueExpression()
   * @model containment="true"
   * @generated
   */
  ValueExpression getValueExpression();

  /**
   * Sets the value of the '{@link tools.vitruv.dsls.mappings.mappingsLanguage.FeatureCondition#getValueExpression <em>Value Expression</em>}' containment reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Value Expression</em>' containment reference.
   * @see #getValueExpression()
   * @generated
   */
  void setValueExpression(ValueExpression value);

  /**
   * Returns the value of the '<em><b>Negated</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <p>
   * If the meaning of the '<em>Negated</em>' attribute isn't clear,
   * there really should be more of a description here...
   * </p>
   * <!-- end-user-doc -->
   * @return the value of the '<em>Negated</em>' attribute.
   * @see #setNegated(boolean)
   * @see tools.vitruv.dsls.mappings.mappingsLanguage.MappingsLanguagePackage#getFeatureCondition_Negated()
   * @model
   * @generated
   */
  boolean isNegated();

  /**
   * Sets the value of the '{@link tools.vitruv.dsls.mappings.mappingsLanguage.FeatureCondition#isNegated <em>Negated</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Negated</em>' attribute.
   * @see #isNegated()
   * @generated
   */
  void setNegated(boolean value);

  /**
   * Returns the value of the '<em><b>Operator</b></em>' attribute.
   * The literals are from the enumeration {@link tools.vitruv.dsls.mappings.mappingsLanguage.MultiValueConditionOperator}.
   * <!-- begin-user-doc -->
   * <p>
   * If the meaning of the '<em>Operator</em>' attribute isn't clear,
   * there really should be more of a description here...
   * </p>
   * <!-- end-user-doc -->
   * @return the value of the '<em>Operator</em>' attribute.
   * @see tools.vitruv.dsls.mappings.mappingsLanguage.MultiValueConditionOperator
   * @see #setOperator(MultiValueConditionOperator)
   * @see tools.vitruv.dsls.mappings.mappingsLanguage.MappingsLanguagePackage#getFeatureCondition_Operator()
   * @model
   * @generated
   */
  MultiValueConditionOperator getOperator();

  /**
   * Sets the value of the '{@link tools.vitruv.dsls.mappings.mappingsLanguage.FeatureCondition#getOperator <em>Operator</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Operator</em>' attribute.
   * @see tools.vitruv.dsls.mappings.mappingsLanguage.MultiValueConditionOperator
   * @see #getOperator()
   * @generated
   */
  void setOperator(MultiValueConditionOperator value);

} // FeatureCondition
