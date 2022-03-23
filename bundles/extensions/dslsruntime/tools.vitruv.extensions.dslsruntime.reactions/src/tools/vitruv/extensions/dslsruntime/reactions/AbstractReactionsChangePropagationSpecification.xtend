package tools.vitruv.extensions.dslsruntime.reactions

import tools.vitruv.framework.domains.VitruvDomain
import tools.vitruv.framework.propagation.impl.CompositeChangePropagationSpecification
import tools.vitruv.framework.change.Metamodel

/**
 * A {@link CompositeChangePropagationSpecification} that contains the reactions change processor.
 * To add further change processors extend the implementing class and override the setup method.
 */
abstract class AbstractReactionsChangePropagationSpecification extends CompositeChangePropagationSpecification {
	new(VitruvDomain sourceDomain, VitruvDomain targetDomain) {
		super(Metamodel.of(sourceDomain.metamodelRootPackage), Metamodel.of(targetDomain.metamodelRootPackage));
		this.setup();
	}

	/**
	 * Adds the reactions change processor to this {@link CompositeChangePropagationSpecification}.
	 * For adding further change processors overwrite this method and call the super method at the right place.
	 */
	protected abstract def void setup();
}
