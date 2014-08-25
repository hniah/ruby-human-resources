class LeavesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @leaves = current_user.is_admin? ? Leave : current_staff.leaves
    @leaves = @leaves.paginate(page: page)
  end

  def new
    @leave = Leave.new
    1.times { @leave.leave_days.build }
  end

  def create
    @leave = Leave.new(leave_param.merge(staff: current_staff))
    if @leave.save
      # Notify HR when new leave come
      LeaveNotifier.new_leave(@leave).deliver
      redirect_to leaves_path, notice: t('leave.message.create_success')
    else
      flash[:alert] = t('leave.message.create_failed')
      render :new
    end
  end

  def edit
    @leave = Leave.find(leave_id)
  end

  def update
    @leave = Leave.find(leave_id)
    if @leave.update(leave_param)
      redirect_to leaves_path, notice: t('leave.message.update_success')
    else
      flash[:alert] = t('leave.message.update_failed')
      render :edit
    end
  end

  def destroy
    @leave = Leave.find(leave_id)
    if @leave.destroy
      redirect_to leaves_path, notice: t('leave.message.delete_success')
    else
      flash[:alert] = t('leave.message.create_failed')
      render :index
    end
  end

  protected
  def page
    params[:page]
  end

  def leave_id
    params.require(:id)
  end

  def leave_param
    params.require(:leave).permit(:reason, :staff_id, :category, leave_days_attributes: [ :date, :kind, :id ])
  end

  def current_staff
    current_user.becomes(Staff)
  end
end
