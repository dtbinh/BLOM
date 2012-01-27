function [cost_name costGrad_name eqconstr_name eqconstrGrad_name neqconstr_name neqconstrGrad_name ...
          Aeq Beq A B ]...
    =CreateIpoptCPP(name,all_names, AAs ,  Cs , ineq,cost,separate_linear)



for i = 1:length(all_names)
    idx_names{i} = sprintf('x[%d]',i);
end


cost_grad = CreateGradient(cost.A,cost.C);


for i=1:length(AAs)
    eq_grad{i} = CreateGradient(AAs{i},Cs{i});
end


for i=1:length(ineq.AAs)
    ineq_grad{i} = CreateGradient(ineq.AAs{i},ineq.Cs{i});
end

for j=1:length(idx_names)
    cost_hessian{j} = CreateGradient(cost_grad.AAs{j},cost_grad.Cs{j});
end


for i=1:length(ineq_grad)
    for j=1:length(idx_names)
        ineq_hessian{i,j} = CreateGradient(ineq_grad{i}.AAs{j},ineq_grad{i}.Cs{j});
    end
end

for i=1:length(eq_grad)
    for j=1:length(idx_names)
        eq_hessian{i,j} = CreateGradient(eq_grad{i}.AAs{j},eq_grad{i}.Cs{j});
    end
end

%%%%%%%%%%%%%%%%%%%%%%

nnz_h_lag = CreateHessian(name,idx_names,cost_hessian,ineq_hessian,eq_hessian);

nnz_jac_g = CreateJacobian(name,idx_names,ineq_grad,eq_grad);

eq.AAs = AAs;
eq.Cs = Cs;

CreateConstraints(name,idx_names,ineq,eq);

CreateCost(name,idx_names,cost);

CreateCostGrad(name,idx_names,cost_grad);

 Create_get_nlp_info(name,length(idx_names), length(ineq.AAs) + length(eq.AAs),nnz_jac_g,nnz_h_lag);
 Create_get_bounds_info(name,length(idx_names),length(ineq.AAs) + length(eq.AAs),length(ineq.AAs));


function Create_get_nlp_info(name,n,m,nnz_jac_g,nnz_h_lag)

get_nlp_info = fopen([name 'get_nlp_info.cpp'],'wt');

%   // The problem described in MyNLP.hpp has 2 variables, x1, & x2,
%   n = 2;
% 
%   // one equality constraint,
%   m = 1;
% 
%   // 2 nonzeros in the jacobian (one for x1, and one for x2),
%   nnz_jac_g = 2;
% 
%   // and 2 nonzeros in the hessian of the lagrangian
%   // (one in the hessian of the objective for x2,
%   //  and one in the hessian of the constraints for x1)
%   nnz_h_lag = 2;
% 
%   // We use the standard fortran index style for row/col entries
%   index_style = FORTRAN_STYLE;
  
  

fprintf(get_nlp_info,'n=%d ;\n', n);
fprintf(get_nlp_info,'m=%d ;\n', m);
fprintf(get_nlp_info,'nnz_jac_g =%d ;\n', nnz_jac_g);
fprintf(get_nlp_info,'nnz_h_lag =%d ;\n', nnz_h_lag);
fprintf(get_nlp_info,' index_style = FORTRAN_STYLE;\n');

fclose(get_nlp_info);

function Create_get_bounds_info(name,n,m,ineq_length)

get_bounds_info  = fopen([name 'get_bounds_info.cpp'],'wt');

for i=1:n
    fprintf(get_bounds_info,'x_l[%d] = -1.0e19;\n', i);
    fprintf(get_bounds_info,'x_u[%d] = +1.0e19;\n', i);
end

for i=1:ineq_length
    fprintf(get_bounds_info,'g_l[%d] = -1.0e19;\n', i);
    fprintf(get_bounds_info,'g_l[%d] = 0;\n', i);
end


for i=ineq_length:m
    fprintf(get_bounds_info,'g_l[%d] = 0;\n', i);
    fprintf(get_bounds_info,'g_l[%d] = 0;\n', i);
end

fclose(get_bounds_info);

function CreateCost(name,names,cost)

feval_f = fopen([name 'eval_f.cpp'],'wt');



str = CreatePolyFromMatrix(cost.A,cost.C,names);


fprintf(feval_f,'obj_value=%s ;\n', str);

fclose(feval_f);

function CreateCostGrad(name,names,cost_grad)

feval_grad_f = fopen([name 'eval_grad_f.cpp'],'wt');

for i=1:length(cost_grad.AAs) 
        str = '0';
        
            if  ~isempty(cost_grad.AAs) && ~isempty(cost_grad.AAs{i})

                str = CreatePolyFromMatrix(cost_grad.AAs{i},cost_grad.Cs{i},names);
            end
        
        
          fprintf(feval_grad_f,'grad_f[%d]=%s ;\n', i,str);

end

fclose(feval_grad_f);


function CreateConstraints(name,names,ineq,eq)

feval_g = fopen([name 'eval_g.cpp'],'wt');

for i=1:length(ineq.AAs) + length(eq.AAs)
        str = '0';
        
        if (i <= length(ineq.AAs))
            if  ~isempty(ineq.AAs) && ~isempty(ineq.AAs{i})

                str = CreatePolyFromMatrix(ineq.AAs{i},ineq.Cs{i},names);
            end
        else
            k = i - length(ineq.AAs); 
            if ~isempty(eq.AAs) && ~isempty(eq.AAs{k})

                str = CreatePolyFromMatrix(eq.AAs{k},eq.Cs{k},names);
            end
        end
        
        
          fprintf(feval_g,'g[%d]=%s ;\n', i,str);

end

fclose(feval_g);


function nnz_h_lag = CreateHessian(name,names,cost_hessian,ineq_hessian,eq_hessian)

nnz_h_lag=  0 ;

feval_h_val = fopen([name 'eval_h_val.cpp'],'wt');
feval_h_idx = fopen([name 'eval_h_idx.cpp'],'wt');

for i=1:length(names)
    for j=i:length(names)
        nz = 0;
        str = '';
        if  ~isempty(cost_hessian{i}.AAs) &&  ~isempty(cost_hessian{i}.AAs{j}) 
            nz = 1;
            str = CreatePolyFromMatrix(cost_hessian{i}.AAs{j},cost_hessian{i}.Cs{j},names);
            str = [ 'obj_factor*(' str ')'];
        end

        for k = 1:size(ineq_hessian,1)
            if  ~isempty(ineq_hessian{k,i}.AAs) && ~isempty(ineq_hessian{k,i}.AAs{j})
                nz = 1;
                tmp = CreatePolyFromMatrix(ineq_hessian{k,i}.AAs{j},ineq_hessian{k,i}.Cs{j},names);
                str = [tmp  '+lambda[' num2str(k-1) ']*(' tmp ')' ];
            end
        end
        
        for k = 1:size(eq_hessian,1)
            if ~isempty(ineq_hessian{k,i}.AAs) && ~isempty(ineq_hessian{k,i}.AAs{j})
                nz = 1;
                tmp = CreatePolyFromMatrix(eq_hessian{k,i}.AAs{j},eq_hessian{k,i}.Cs{j},names);
                str = [tmp  '+lambda[' num2str(k-1+size(ineq_hessian,1)) ']*(' tmp ')' ];
            end
        end
        if (nz == 1)
          nnz_h_lag = nnz_h_lag + 1;
          fprintf(feval_h_val,'values[%d]=%s ;\n', nnz_h_lag,str);
          fprintf(feval_h_idx,'iRow[%d]=%d ;\n', nnz_h_lag,i);
          fprintf(feval_h_idx,'jCol[%d]=%d ;\n', nnz_h_lag,j);
        end
    end
end

fclose(feval_h_val);
fclose(feval_h_idx);

function nnz_jac_g = CreateJacobian(name,names,ineq_grad,eq_grad)

nnz_jac_g=  0 ;

feval_jac_g_val = fopen([name 'eval_jac_g_val.cpp'],'wt');
feval_jac_g_idx = fopen([name 'eval_jac_g_idx.cpp'],'wt');

for i=1:length(ineq_grad) + length(eq_grad)
    for j=i:length(names)
        nz = 0;
        str = '';
        
        if (i <= length(ineq_grad))
            if  ~isempty(ineq_grad{i}.AAs) && ~isempty(ineq_grad{i}.AAs{j})
                nz = 1;
                str = CreatePolyFromMatrix(ineq_grad{i}.AAs{j},ineq_grad{i}.Cs{j},names);
            end
        else
            k = i - length(ineq_grad); 
            if ~isempty(eq_grad{k}.AAs) && ~isempty(eq_grad{k}.AAs{j})
                nz = 1;
                str = CreatePolyFromMatrix(eq_grad{k}.AAs{j},eq_grad{k}.Cs{j},names);
            end
        end
        
        
        if (nz == 1)
          nnz_jac_g = nnz_jac_g + 1;
          fprintf(feval_jac_g_val,'values[%d]=%s ;\n', nnz_jac_g,str);
          fprintf(feval_jac_g_idx,'iRow[%d]=%d ;\n', nnz_jac_g,i);
          fprintf(feval_jac_g_idx,'jCol[%d]=%d ;\n', nnz_jac_g,j);
        end
    end
end

fclose(feval_jac_g_val);
fclose(feval_jac_g_idx);

function PrintFunction(name,str)

f = fopen([name '.cpp'],'wt');

fprintf(f,'%%#eml\n');
fprintf(f,'function y = %s(x)\n\n',name);

if ~iscell(str)
    str = {str};
end

MinimumMatrixSizeForSpare = 40;

if size(str,1)*size(str,2) == 1  
    % do not initialize
elseif size(str,1)*size(str,2) > MinimumMatrixSizeForSpare 
    % sparse
    fprintf(f,'y = sparse(%d,%d,0);\n\n',size(str,2),size(str,1));
else
    fprintf(f,'y = zeros(%d,%d);\n\n',size(str,2),size(str,1));
end

for i=1:size(str,1)
    for j=1:size(str,2)
        if ~strcmp(str{i,j},'0')
            fprintf(f,'y(%d,%d) = %s ; \n',j,i,str{i,j});
        end
    end
end

fclose(f);


function [ Matrix , B,   nlAAs , nlCs ] = ExtractLinearPart(AAs,Cs)

l=1;
nl=1;
Matrix = [];
B = [];
nlAAs = {};
nlCs  = {};
for i = 1:length(AAs)
    if IsLinear(AAs{i})
        for j=1:size(Cs{i},1)
            Matrix(l,:) = Cs{i}(j,:)*AAs{i};
            idx = find(sum(AAs{i}')==0);% find constant terms
            if isempty(idx)
                B(l) = 0;
            else
                B(l) = -sum(Cs{i}(j,idx));
            end

            l=l+1;
        end
       else
           nlAAs{nl} = AAs{i};
           nlCs{nl} = Cs{i};
           nl = nl+1;
       end
           
    
end

Matrix = sparse(Matrix);

function is_linear = IsLinear(A)
if (max(sum(A'))<=1)&& (min(sum(A')) > -1 )
    is_linear = true;
else
    is_linear = false;
end
    
 