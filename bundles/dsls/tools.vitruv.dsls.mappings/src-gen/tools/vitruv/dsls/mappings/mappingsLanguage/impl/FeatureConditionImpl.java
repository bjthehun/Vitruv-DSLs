/**
 * generated by Xtext 2.12.0
 */
package tools.vitruv.dsls.mappings.mappingsLanguage.impl;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;

import org.eclipse.emf.ecore.impl.ENotificationImpl;

import tools.vitruv.dsls.mappings.mappingsLanguage.FeatureCondition;
import tools.vitruv.dsls.mappings.mappingsLanguage.MappingsLanguagePackage;
import tools.vitruv.dsls.mappings.mappingsLanguage.MultiValueConditionOperator;
import tools.vitruv.dsls.mappings.mappingsLanguage.ValueExpression;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Feature Condition</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link tools.vitruv.dsls.mappings.mappingsLanguage.impl.FeatureConditionImpl#getValueExpression <em>Value Expression</em>}</li>
 *   <li>{@link tools.vitruv.dsls.mappings.mappingsLanguage.impl.FeatureConditionImpl#isNegated <em>Negated</em>}</li>
 *   <li>{@link tools.vitruv.dsls.mappings.mappingsLanguage.impl.FeatureConditionImpl#getOperator <em>Operator</em>}</li>
 * </ul>
 *
 * @generated
 */
public class FeatureConditionImpl extends EnforceableConditionImpl implements FeatureCondition
{
  /**
   * The cached value of the '{@link #getValueExpression() <em>Value Expression</em>}' containment reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getValueExpression()
   * @generated
   * @ordered
   */
  protected ValueExpression valueExpression;

  /**
   * The default value of the '{@link #isNegated() <em>Negated</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isNegated()
   * @generated
   * @ordered
   */
  protected static final boolean NEGATED_EDEFAULT = false;

  /**
   * The cached value of the '{@link #isNegated() <em>Negated</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isNegated()
   * @generated
   * @ordered
   */
  protected boolean negated = NEGATED_EDEFAULT;

  /**
   * The default value of the '{@link #getOperator() <em>Operator</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getOperator()
   * @generated
   * @ordered
   */
  protected static final MultiValueConditionOperator OPERATOR_EDEFAULT = MultiValueConditionOperator.EQUALS;

  /**
   * The cached value of the '{@link #getOperator() <em>Operator</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getOperator()
   * @generated
   * @ordered
   */
  protected MultiValueConditionOperator operator = OPERATOR_EDEFAULT;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  protected FeatureConditionImpl()
  {
    super();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  protected EClass eStaticClass()
  {
    return MappingsLanguagePackage.Literals.FEATURE_CONDITION;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public ValueExpression getValueExpression()
  {
    return valueExpression;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public NotificationChain basicSetValueExpression(ValueExpression newValueExpression, NotificationChain msgs)
  {
    ValueExpression oldValueExpression = valueExpression;
    valueExpression = newValueExpression;
    if (eNotificationRequired())
    {
      ENotificationImpl notification = new ENotificationImpl(this, Notification.SET, MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION, oldValueExpression, newValueExpression);
      if (msgs == null) msgs = notification; else msgs.add(notification);
    }
    return msgs;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public void setValueExpression(ValueExpression newValueExpression)
  {
    if (newValueExpression != valueExpression)
    {
      NotificationChain msgs = null;
      if (valueExpression != null)
        msgs = ((InternalEObject)valueExpression).eInverseRemove(this, EOPPOSITE_FEATURE_BASE - MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION, null, msgs);
      if (newValueExpression != null)
        msgs = ((InternalEObject)newValueExpression).eInverseAdd(this, EOPPOSITE_FEATURE_BASE - MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION, null, msgs);
      msgs = basicSetValueExpression(newValueExpression, msgs);
      if (msgs != null) msgs.dispatch();
    }
    else if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION, newValueExpression, newValueExpression));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public boolean isNegated()
  {
    return negated;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public void setNegated(boolean newNegated)
  {
    boolean oldNegated = negated;
    negated = newNegated;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, MappingsLanguagePackage.FEATURE_CONDITION__NEGATED, oldNegated, negated));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public MultiValueConditionOperator getOperator()
  {
    return operator;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public void setOperator(MultiValueConditionOperator newOperator)
  {
    MultiValueConditionOperator oldOperator = operator;
    operator = newOperator == null ? OPERATOR_EDEFAULT : newOperator;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, MappingsLanguagePackage.FEATURE_CONDITION__OPERATOR, oldOperator, operator));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs)
  {
    switch (featureID)
    {
      case MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION:
        return basicSetValueExpression(null, msgs);
    }
    return super.eInverseRemove(otherEnd, featureID, msgs);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Object eGet(int featureID, boolean resolve, boolean coreType)
  {
    switch (featureID)
    {
      case MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION:
        return getValueExpression();
      case MappingsLanguagePackage.FEATURE_CONDITION__NEGATED:
        return isNegated();
      case MappingsLanguagePackage.FEATURE_CONDITION__OPERATOR:
        return getOperator();
    }
    return super.eGet(featureID, resolve, coreType);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void eSet(int featureID, Object newValue)
  {
    switch (featureID)
    {
      case MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION:
        setValueExpression((ValueExpression)newValue);
        return;
      case MappingsLanguagePackage.FEATURE_CONDITION__NEGATED:
        setNegated((Boolean)newValue);
        return;
      case MappingsLanguagePackage.FEATURE_CONDITION__OPERATOR:
        setOperator((MultiValueConditionOperator)newValue);
        return;
    }
    super.eSet(featureID, newValue);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void eUnset(int featureID)
  {
    switch (featureID)
    {
      case MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION:
        setValueExpression((ValueExpression)null);
        return;
      case MappingsLanguagePackage.FEATURE_CONDITION__NEGATED:
        setNegated(NEGATED_EDEFAULT);
        return;
      case MappingsLanguagePackage.FEATURE_CONDITION__OPERATOR:
        setOperator(OPERATOR_EDEFAULT);
        return;
    }
    super.eUnset(featureID);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean eIsSet(int featureID)
  {
    switch (featureID)
    {
      case MappingsLanguagePackage.FEATURE_CONDITION__VALUE_EXPRESSION:
        return valueExpression != null;
      case MappingsLanguagePackage.FEATURE_CONDITION__NEGATED:
        return negated != NEGATED_EDEFAULT;
      case MappingsLanguagePackage.FEATURE_CONDITION__OPERATOR:
        return operator != OPERATOR_EDEFAULT;
    }
    return super.eIsSet(featureID);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String toString()
  {
    if (eIsProxy()) return super.toString();

    StringBuffer result = new StringBuffer(super.toString());
    result.append(" (negated: ");
    result.append(negated);
    result.append(", operator: ");
    result.append(operator);
    result.append(')');
    return result.toString();
  }

} //FeatureConditionImpl
